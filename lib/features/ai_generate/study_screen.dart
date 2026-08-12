import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/groq_provider.dart';
import '../../core/models/prompt_template.dart';
import '../../core/services/question_generation_service.dart' as qgs;

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final TextEditingController _textController = TextEditingController();
  String _generatedOutput = '';
  bool _isLoading = false;

  Future<void> _generateDeck() async {
    if (_textController.text.trim().isEmpty) return;

    final groqProvider = Provider.of<GroqProvider>(context, listen: false);
    
    if (!groqProvider.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure your Groq API key first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedOutput = '';
    });

    try {
      final generationService = qgs.QuestionGenerationService(groqProvider.service);
      
      final questions = await generationService.generateQuestions(
        sourceText: _textController.text,
        type: PromptType.studyDeck,
        difficulty: Difficulty.medium,
        questionCount: 15,
        model: groqProvider.selectedModel,
      );

      if (!mounted) return;

      // Format questions as text output
      final formattedOutput = _formatQuestionsAsText(questions);

      setState(() {
        _generatedOutput = formattedOutput;
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatQuestionsAsText(List<qgs.GeneratedQuestion> questions) {
    final buffer = StringBuffer();
    
    buffer.writeln('SECTION 1: STUDY FLASHCARDS AND EXAM PAPER');
    buffer.writeln();
    
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      buffer.writeln('Item ${i + 1} | Multiple Choice | Medium');
      buffer.writeln('Question Prompt: ${q.question}');
      
      if (q.options.isNotEmpty) {
        buffer.writeln('Options:');
        for (int j = 0; j < q.options.length; j++) {
          buffer.writeln('${String.fromCharCode(65 + j)}) ${q.options[j]}');
        }
      }
      buffer.writeln();
    }
    
    buffer.writeln('SECTION 2: ANSWER KEY AND EXPLANATIONS');
    buffer.writeln();
    
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final answer = q.answer ?? (q.options.isNotEmpty ? q.options[q.correctAnswerIndex] : '');
      buffer.writeln('Item ${i + 1} Answer: $answer');
      if (q.explanation != null) {
        buffer.writeln('Explanation: ${q.explanation}');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Groq AI Flashcard Generator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste extracted PDF / DOCX text here...',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateDeck,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate Study Deck'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _generatedOutput.isEmpty
                      ? 'No flashcards generated yet.'
                      : _generatedOutput,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
