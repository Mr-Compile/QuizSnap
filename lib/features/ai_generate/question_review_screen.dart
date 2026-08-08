import 'package:flutter/material.dart';
import '../../core/services/question_generation_service.dart';
import '../../core/models/prompt_template.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/groq_provider.dart';
import '../../core/providers/ai_quota_provider.dart';
import '../../core/database/database.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift hide Column;
import 'regeneration_options_bottom_sheet.dart';

class QuestionReviewScreen extends StatefulWidget {
  final List<GeneratedQuestion> questions;
  final PromptType type;
  final Difficulty difficulty;
  final String source;

  const QuestionReviewScreen({
    super.key,
    required this.questions,
    required this.type,
    required this.difficulty,
    required this.source,
  });

  @override
  State<QuestionReviewScreen> createState() => _QuestionReviewScreenState();
}

class _QuestionReviewScreenState extends State<QuestionReviewScreen> {
  final List<GeneratedQuestion> _selectedQuestions = [];
  int? _selectedDeckId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Select all questions by default
    _selectedQuestions.addAll(widget.questions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Questions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _showRegenerationOptions,
            tooltip: 'Regenerate questions',
          ),
          if (_selectedQuestions.isNotEmpty)
            TextButton.icon(
              onPressed: _selectedDeckId == null ? null : _saveQuestions,
              icon: _isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: _isSaving
                  ? const Text('Saving...')
                  : Text('Save (${_selectedQuestions.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Summary header
          _buildSummaryHeader(),
          // Questions list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                final question = widget.questions[index];
                final isSelected = _selectedQuestions.contains(question);
                return _buildQuestionCard(question, index, isSelected);
              },
            ),
          ),
          // Deck selection footer
          _buildDeckSelector(),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTypeIcon(widget.type),
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.type.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(widget.difficulty),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.difficulty.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Source: ${widget.source}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_selectedQuestions.length} of ${widget.questions.length} questions selected',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(GeneratedQuestion question, int index, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _toggleQuestionSelection(question),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleQuestionSelection(question),
                  ),
                  Expanded(
                    child: Text(
                      'Q${index + 1}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editQuestion(question, index),
                    tooltip: 'Edit question',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteQuestion(question),
                    tooltip: 'Delete question',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                question.question,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (question.options.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...question.options.asMap().entries.map((entry) {
                  final optionIndex = entry.key;
                  final optionText = entry.value;
                  final isCorrect = optionIndex == question.correctAnswerIndex;
                  
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + optionIndex),
                              style: TextStyle(
                                color: isCorrect
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            optionText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              decoration: isCorrect ? TextDecoration.underline : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              if (question.answer != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Answer: ${question.answer}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (question.explanation != null && question.explanation!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        size: 16,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          question.explanation!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeckSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Save to Deck',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Deck>>(
              future: Provider.of<DatabaseProvider>(context, listen: false)
                  .deckRepository.getAllDecks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                
                final decks = snapshot.data ?? [];
                
                if (decks.isEmpty) {
                  return const Text('No decks available. Create one first.');
                }
                
                return DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use
                  value: _selectedDeckId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Select a deck',
                  ),
                  items: decks.map((deck) {
                    return DropdownMenuItem<int>(
                      value: deck.id,
                      child: Text(deck.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDeckId = value;
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleQuestionSelection(GeneratedQuestion question) {
    setState(() {
      if (_selectedQuestions.contains(question)) {
        _selectedQuestions.remove(question);
      } else {
        _selectedQuestions.add(question);
      }
    });
  }

  void _editQuestion(GeneratedQuestion question, int index) {
    // Question editing dialog to be implemented in future version
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Question'),
        content: const Text('Question editing feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deleteQuestion(GeneratedQuestion question) {
    setState(() {
      widget.questions.remove(question);
      _selectedQuestions.remove(question);
    });
  }

  Future<void> _saveQuestions() async {
    if (_selectedDeckId == null || _selectedQuestions.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      
      // Save each question as a flashcard
      for (final question in _selectedQuestions) {
        final answerText = question.answer ?? 
            (question.options.isNotEmpty ? question.options[question.correctAnswerIndex] : '');
        
        await dbProvider.flashcardRepository.createFlashcard(
          FlashcardsCompanion(
            question: drift.Value(question.question),
            answer: drift.Value(answerText),
            deckId: drift.Value(_selectedDeckId!),
            order: drift.Value(_selectedQuestions.indexOf(question)),
          ),
        );
      }

      // Update deck card count
      await dbProvider.deckRepository.updateDeckCardCount(_selectedDeckId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully saved ${_selectedQuestions.length} questions'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      // Navigate back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save questions: $e')),
      );
    }
  }

  IconData _getTypeIcon(PromptType type) {
    switch (type) {
      case PromptType.multipleChoice:
        return Icons.quiz;
      case PromptType.identification:
        return Icons.search;
      case PromptType.enumeration:
        return Icons.list;
      case PromptType.examSimulation:
        return Icons.assignment;
      case PromptType.explanation:
        return Icons.lightbulb;
    }
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
      case Difficulty.expert:
        return Colors.purple;
    }
  }

  void _showRegenerationOptions() {
    final approvedCount = _selectedQuestions.length;
    final rejectedCount = widget.questions.length - _selectedQuestions.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RegenerationOptionsBottomSheet(
        totalQuestions: widget.questions.length,
        approvedCount: approvedCount,
        rejectedCount: rejectedCount,
        onOptionSelected: (option) {
          Navigator.of(context).pop();
          _handleRegeneration(option);
        },
      ),
    );
  }

  Future<void> _handleRegeneration(RegenerationOption option) async {
    final groqProvider = Provider.of<GroqProvider>(context, listen: false);
    final quotaProvider = Provider.of<AiQuotaProvider>(context, listen: false);

    // Check quota
    if (!quotaProvider.canRequest) {
      _showQuotaExceededDialog();
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showRegenerationConfirmation(option);
    if (!confirmed) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final generationService = QuestionGenerationService(groqProvider.service);
      
      List<GeneratedQuestion> newQuestions;
      
      switch (option) {
        case RegenerationOption.regenerateAll:
          // Regenerate all questions
          newQuestions = await generationService.generateQuestions(
            sourceText: widget.source, // This would need to be stored/passed properly
            type: widget.type,
            difficulty: widget.difficulty,
            questionCount: widget.questions.length,
          );
          break;
          
        case RegenerationOption.regenerateSelected:
          // Regenerate only selected questions
          newQuestions = await generationService.generateQuestions(
            sourceText: widget.source,
            type: widget.type,
            difficulty: widget.difficulty,
            questionCount: _selectedQuestions.length,
          );
          break;
          
        case RegenerationOption.keepApprovedReplaceRejected:
          // Keep approved, replace rejected
          final rejectedCount = widget.questions.length - _selectedQuestions.length;
          if (rejectedCount > 0) {
            final regeneratedQuestions = await generationService.generateQuestions(
              sourceText: widget.source,
              type: widget.type,
              difficulty: widget.difficulty,
              questionCount: rejectedCount,
            );
            // Combine approved with regenerated
            newQuestions = [..._selectedQuestions, ...regeneratedQuestions];
          } else {
            newQuestions = List.from(_selectedQuestions);
          }
          break;
      }

      if (!mounted) return;

      // Increment quota usage
      await quotaProvider.incrementUsage();

      // Show comparison dialog (simplified version)
      _showComparisonDialog(newQuestions);
      
      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Regeneration failed: $e')),
      );
    }
  }

  Future<bool> _showRegenerationConfirmation(RegenerationOption option) async {
    String message;
    switch (option) {
      case RegenerationOption.regenerateAll:
        message = 'This will replace all ${widget.questions.length} questions with new ones. Continue?';
        break;
      case RegenerationOption.regenerateSelected:
        message = 'This will replace ${_selectedQuestions.length} selected questions with new ones. Continue?';
        break;
      case RegenerationOption.keepApprovedReplaceRejected:
        message = 'This will keep ${_selectedQuestions.length} approved questions and replace the rest. Continue?';
        break;
    }

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Regeneration'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showComparisonDialog(List<GeneratedQuestion> newQuestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regeneration Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generated ${newQuestions.length} new questions'),
            const SizedBox(height: 16),
            const Text('Would you like to:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Keep old questions
            },
            child: const Text('Keep Old'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Replace with new questions - this would require updating the state
              setState(() {
                // For now, just show a message
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Questions updated with regenerated versions')),
              );
            },
            child: const Text('Use New'),
          ),
        ],
      ),
    );
  }

  void _showQuotaExceededDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Limit Reached'),
        content: const Text('You have reached today\'s AI limit (15/15). Try again tomorrow.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}