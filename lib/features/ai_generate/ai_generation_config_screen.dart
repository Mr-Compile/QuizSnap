import 'package:flutter/material.dart';
import '../../core/models/prompt_template.dart';
import '../../core/providers/groq_provider.dart';
import '../../core/services/question_generation_service.dart';
import 'package:provider/provider.dart';
import 'question_review_screen.dart';

class AiGenerationConfigScreen extends StatefulWidget {
  final String sourceText;
  final String source;

  const AiGenerationConfigScreen({
    super.key,
    required this.sourceText,
    required this.source,
  });

  @override
  State<AiGenerationConfigScreen> createState() => _AiGenerationConfigScreenState();
}

class _AiGenerationConfigScreenState extends State<AiGenerationConfigScreen> {
  PromptType _selectedType = PromptType.multipleChoice;
  Difficulty _selectedDifficulty = Difficulty.medium;
  int _questionCount = 10;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Generation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Source info
          _buildSourceInfo(),
          const SizedBox(height: 24),
          
          // Question type selection
          _buildSectionTitle('Question Type'),
          const SizedBox(height: 12),
          _buildQuestionTypeSelector(),
          const SizedBox(height: 24),
          
          // Difficulty selection
          _buildSectionTitle('Difficulty'),
          const SizedBox(height: 12),
          _buildDifficultySelector(),
          const SizedBox(height: 24),
          
          // Question count
          _buildSectionTitle('Number of Questions'),
          const SizedBox(height: 12),
          _buildQuestionCountSelector(),
          const SizedBox(height: 24),
          
          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _startGeneration,
              child: _isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 16),
                        Text('Generating...'),
                      ],
                    )
                  : const Text('Generate Questions'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Source: ${widget.source}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Text length: ${widget.sourceText.length} characters',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  Widget _buildQuestionTypeSelector() {
    return Column(
      children: PromptType.values.map((type) {
        final isSelected = _selectedType == type;
        return RadioListTile<PromptType>(
          title: Row(
            children: [
              Text(
                type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Text(type.displayName),
            ],
          ),
          subtitle: Text(_getTypeDescription(type)),
          value: type,
          groupValue: _selectedType,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedType = value;
              });
            }
          },
          selected: isSelected,
        );
      }).toList(),
    );
  }

  String _getTypeDescription(PromptType type) {
    switch (type) {
      case PromptType.multipleChoice:
        return 'Questions with multiple answer options';
      case PromptType.identification:
        return 'Direct answer questions';
      case PromptType.enumeration:
        return 'List-based questions';
      case PromptType.examSimulation:
        return 'Mixed question types for exam practice';
      case PromptType.explanation:
        return 'Questions with detailed explanations';
    }
  }

  Widget _buildDifficultySelector() {
    return Column(
      children: Difficulty.values.map((difficulty) {
        final isSelected = _selectedDifficulty == difficulty;
        return RadioListTile<Difficulty>(
          title: Text(difficulty.displayName),
          subtitle: Text(difficulty.description),
          value: difficulty,
          groupValue: _selectedDifficulty,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedDifficulty = value;
              });
            }
          },
          selected: isSelected,
        );
      }).toList(),
    );
  }

  Widget _buildQuestionCountSelector() {
    return Column(
      children: [
        Slider(
          value: _questionCount.toDouble(),
          min: 5,
          max: 50,
          divisions: 9,
          label: _questionCount.toString(),
          onChanged: (value) {
            setState(() {
              _questionCount = value.round();
            });
          },
        ),
        Center(
          child: Text(
            '$_questionCount questions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Text(
          'More questions may take longer to generate',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Future<void> _startGeneration() async {
    final groqProvider = Provider.of<GroqProvider>(context, listen: false);
    
    if (!groqProvider.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure your Groq API key first')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final generationService = QuestionGenerationService(groqProvider.service);
      
      final questions = await generationService.generateQuestions(
        sourceText: widget.sourceText,
        type: _selectedType,
        difficulty: _selectedDifficulty,
        questionCount: _questionCount,
      );

      if (!mounted) return;

      // Validate questions
      final issues = generationService.validateQuestions(questions);
      if (issues.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Some questions have issues: ${issues.first}')),
        );
      }

      // Navigate to review screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => QuestionReviewScreen(
            questions: questions,
            type: _selectedType,
            difficulty: _selectedDifficulty,
            source: widget.source,
          ),
        ),
      );
      
      setState(() {
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isGenerating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generation failed: $e')),
      );
    }
  }
}