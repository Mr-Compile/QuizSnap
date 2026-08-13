import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/question_generation_service.dart';
import '../../core/models/prompt_template.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/groq_provider.dart';
import '../../core/providers/ai_quota_provider.dart';
import '../../core/providers/notification_service.dart';
import '../../core/repositories/recent_generation_repository.dart';
import '../../core/database/database.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift hide Column;
import 'package:go_router/go_router.dart';
import '../../core/utils/explanation_sanitizer.dart';
import '../../core/services/question_validation_service.dart';
import '../../shared/widgets/formatted_study_text.dart';
import 'regeneration_options_bottom_sheet.dart';
import 'text_preview_screen.dart';
import 'ai_generation_config_screen.dart';

class QuestionReviewScreen extends StatefulWidget {
  final List<GeneratedQuestion> questions;
  final PromptType type;
  final Difficulty difficulty;
  final String source;
  final String sourceText;
  final String? generationId;

  const QuestionReviewScreen({
    super.key,
    required this.questions,
    required this.type,
    required this.difficulty,
    required this.source,
    this.sourceText = '',
    this.generationId,
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
    // Show empty state UI if no questions were generated
    if (widget.questions.isEmpty) {
      return _buildEmptyState(context);
    }

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
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
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
    final warnings = MultipleChoiceQuestionValidator.validate(
      options: question.options,
      correctAnswerIndex: question.correctAnswerIndex,
      questionIndex: index,
      answer: question.answer,
    );
    final isInvalid = warnings.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: 'Question ${index + 1} ${isSelected ? 'selected' : 'not selected'}',
        selected: isSelected,
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
                    Semantics(
                      button: true,
                      label: 'Edit question ${index + 1}',
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editQuestion(question, index),
                        tooltip: 'Edit question',
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Delete question ${index + 1}',
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteQuestion(question),
                        tooltip: 'Delete question',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FormattedStudyText(
                  text: question.question,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (isInvalid) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            warnings.join('\n'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (question.options.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...question.options.take(4).toList().asMap().entries.map((entry) {
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
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormattedStudyText(
                              text: _cleanOptionText(optionText),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                decoration: isCorrect ? TextDecoration.underline : null,
                              ),
                              showActions: false,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (question.correctAnswerIndex >= 0 && question.correctAnswerIndex < question.options.length) ...[
                    const SizedBox(height: 12),
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
                              'Correct Answer: ${String.fromCharCode(65 + question.correctAnswerIndex)}. ${_cleanOptionText(question.options[question.correctAnswerIndex])}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                if (question.answer != null && question.options.isEmpty) ...[
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
                            'Answer: ${QuestionGenerationService.sanitizeText(question.answer ?? '')}',
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
                          child: FormattedStudyText(
                            text: ExplanationSanitizer.sanitize(question.explanation),
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
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GeneratedQuestionEditorScreen(
          question: question,
          index: index,
          onSave: (editedQuestion) {
            setState(() {
              widget.questions[index] = editedQuestion;
            });
          },
        ),
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

    final recentRepo = widget.generationId != null
        ? context.read<RecentGenerationRepository>()
        : null;

    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);

      // Save each question as a flashcard
      for (final question in _selectedQuestions) {
        final answerText = question.options.isNotEmpty
            ? question.options[question.correctAnswerIndex]
            : (question.answer ?? '');
        
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

      // Track that this recent generation was saved to a deck.
      if (recentRepo != null) {
        await recentRepo.updateSavedDeckId(widget.generationId!, _selectedDeckId!);
      }

      if (!mounted) return;

      context.read<NotificationService>().showSuccess(
        'Successfully saved ${_selectedQuestions.length} questions',
      );

      // Navigate back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
      });

      context.read<NotificationService>().showErrorTop('Failed to save questions: $e');
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
      case PromptType.studyDeck:
        return Icons.menu_book;
      case PromptType.mixed:
        return Icons.auto_awesome_mosaic;
    }
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return AppTheme.bambooGreen600;
      case Difficulty.medium:
        return AppTheme.amber600;
      case Difficulty.hard:
        return AppTheme.red600;
      case Difficulty.expert:
        return AppTheme.purple600;
    }
  }

  String _cleanOptionText(String optionText) {
    final sanitized = QuestionGenerationService.sanitizeText(optionText);
    // Strip a leading A) / B. label because the UI already shows the letter.
    // Requires a punctuation marker so "Central" keeps its C.
    return sanitized.replaceFirst(RegExp(r'^\s*[A-Da-d][.)]\s+'), '').trim();
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
            model: groqProvider.selectedModel,
          );
          break;
          
        case RegenerationOption.regenerateSelected:
          // Regenerate only selected questions
          newQuestions = await generationService.generateQuestions(
            sourceText: widget.source,
            type: widget.type,
            difficulty: widget.difficulty,
            questionCount: _selectedQuestions.length,
            model: groqProvider.selectedModel,
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
              model: groqProvider.selectedModel,
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

      context.read<NotificationService>().showErrorTop('Regeneration failed: $e');
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
              context.read<NotificationService>().showSuccess(
                'Questions updated with regenerated versions',
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

  Widget _buildEmptyState(BuildContext context) {
    final preview = widget.sourceText.isEmpty
        ? 'No source text is available.'
        : widget.sourceText.length > 250
            ? '${widget.sourceText.substring(0, 250)}...'
            : widget.sourceText;

    return Scaffold(
      appBar: AppBar(
        title: const Text('No Questions Generated'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.sentiment_dissatisfied,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No questions could be generated',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The AI could not generate questions from the selected content. You can edit the source text, retry with different settings, or create a flashcard manually.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Extracted text preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                preview,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 32),
            _buildSuggestionCard(
              context,
              icon: Icons.filter_list,
              title: 'Try selecting fewer pages',
              description: 'Reducing the content scope may help generate better questions.',
            ),
            const SizedBox(height: 12),
            _buildSuggestionCard(
              context,
              icon: Icons.bookmark,
              title: 'Try a specific chapter or heading',
              description: 'Focus on a specific section rather than the entire document.',
            ),
            const SizedBox(height: 12),
            _buildSuggestionCard(
              context,
              icon: Icons.quiz,
              title: 'Try a different question type',
              description: 'Some question types work better with certain content.',
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _editText,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Source Text'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _retryGeneration,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Generate'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _changeFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Change File'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _createManually,
              icon: const Icon(Icons.add_card),
              label: const Text('Create Flashcard Manually'),
            ),
          ],
        ),
      ),
    );
  }

  void _editText() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TextPreviewScreen(
          text: widget.sourceText,
          source: widget.source,
        ),
      ),
    );
  }

  void _retryGeneration() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AiGenerationConfigScreen(
          sourceText: widget.sourceText,
          source: widget.source,
        ),
      ),
    );
  }

  void _changeFile() {
    context.go('/ai-generate');
  }

  void _createManually() {
    context.go('/decks');
  }

  Widget _buildSuggestionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Question Editor Screen
class GeneratedQuestionEditorScreen extends StatefulWidget {
  final GeneratedQuestion question;
  final int index;
  final Function(GeneratedQuestion) onSave;

  const GeneratedQuestionEditorScreen({
    super.key,
    required this.question,
    required this.index,
    required this.onSave,
  });

  @override
  State<GeneratedQuestionEditorScreen> createState() => _GeneratedQuestionEditorScreenState();
}

class _GeneratedQuestionEditorScreenState extends State<GeneratedQuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  late final List<TextEditingController> _optionControllers;
  late int _correctAnswerIndex;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question.question);
    _answerController = TextEditingController(text: widget.question.answer ?? '');
    _optionControllers = widget.question.options
        .map((option) => TextEditingController(text: option))
        .toList();
    _correctAnswerIndex = widget.question.options.isEmpty
        ? 0
        : widget.question.correctAnswerIndex.clamp(0, widget.question.options.length - 1);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Question ${widget.index + 1}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _hasUnsavedChanges ? _saveChanges : null,
            tooltip: 'Save',
          ),
        ],
      ),
      body: PopScope(
        canPop: !_hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _hasUnsavedChanges) {
            _showUnsavedChangesDialog();
          }
        },
        child: Form(
          key: _formKey,
          onChanged: () => setState(() => _hasUnsavedChanges = true),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildQuestionField(),
                const SizedBox(height: 16),
                _buildAnswerField(),
                const SizedBox(height: 16),
                _buildOptionsSection(),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _hasUnsavedChanges ? _saveChanges : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionField() {
    return TextFormField(
      controller: _questionController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Question',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Question cannot be empty';
        }
        return null;
      },
      onChanged: (_) => setState(() => _hasUnsavedChanges = true),
    );
  }

  Widget _buildAnswerField() {
    return TextFormField(
      controller: _answerController,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Answer',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Answer cannot be empty';
        }
        return null;
      },
      onChanged: (_) => setState(() => _hasUnsavedChanges = true),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Options',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._optionControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return _buildOptionField(index, controller);
        }),
      ],
    );
  }

  Widget _buildOptionField(int index, TextEditingController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _correctAnswerIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _correctAnswerIndex = index;
                _hasUnsavedChanges = true;
              });
            },
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colorScheme.primary : colorScheme.surface,
                border: Border.all(color: colorScheme.primary),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 18, color: colorScheme.onPrimary)
                  : null,
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Option ${String.fromCharCode(65 + index)}',
                border: const OutlineInputBorder(),
                suffixIcon: _optionControllers.length > 2
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeOption(index),
                      )
                    : null,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Option cannot be empty';
                }
                return null;
              },
              onChanged: (_) => setState(() => _hasUnsavedChanges = true),
            ),
          ),
        ],
      ),
    );
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
      _hasUnsavedChanges = true;
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      if (_correctAnswerIndex >= _optionControllers.length) {
        _correctAnswerIndex = _optionControllers.length - 1;
      }
      _hasUnsavedChanges = true;
    });
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final options = _optionControllers.map((c) => c.text.trim()).toList();

    if (options.isNotEmpty) {
      if (options.length < 2) {
        _showValidationError('Multiple-choice questions need at least 2 options');
        return;
      }
      if (_correctAnswerIndex < 0 || _correctAnswerIndex >= options.length) {
        _showValidationError('Please mark the correct answer');
        return;
      }
    }

    final editedQuestion = GeneratedQuestion(
      question: _questionController.text.trim(),
      answer: _answerController.text.trim().isEmpty ? null : _answerController.text.trim(),
      options: options,
      correctAnswerIndex: _correctAnswerIndex,
      explanation: widget.question.explanation,
    );

    widget.onSave(editedQuestion);
    Navigator.of(context).pop();

    context.read<NotificationService>().showSuccess('Question saved successfully');
  }

  void _showValidationError(String message) {
    context.read<NotificationService>().showErrorTop(message);
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Pop the editor screen
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}