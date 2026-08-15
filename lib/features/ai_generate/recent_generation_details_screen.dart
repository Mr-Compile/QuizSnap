import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift hide Column;
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/models/recent_generation.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../core/repositories/recent_generation_repository.dart';
import '../../core/services/question_generation_service.dart';
import '../../core/services/question_validation_service.dart';
import '../../core/utils/question_type_helper.dart';
import '../../core/models/exam.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import 'question_review_screen.dart';

/// Reopens a recent generation and offers to review or save it to a deck.
class RecentGenerationDetailsScreen extends StatelessWidget {
  final RecentGeneration generation;

  const RecentGenerationDetailsScreen({
    super.key,
    required this.generation,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMd().add_jm().format(generation.generatedAt);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Generation Details',
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context),
            tooltip: 'Delete from history',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              generation.title,
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Generated on $formattedDate',
              style: AppTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Questions: ${generation.questionCount}',
              style: AppTheme.bodyMedium,
            ),
            if (generation.savedDeckId != null) ...[
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Saved to deck ID: ${generation.savedDeckId}',
                style: AppTheme.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingXl),
            CustomButton(
              text: 'Review Questions',
              onPressed: () => _openReview(context),
              fullWidth: true,
              icon: Icons.reviews,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            CustomButton(
              text: 'Save to Deck',
              onPressed: generation.savedDeckId != null ? null : () => _pickDeck(context),
              fullWidth: true,
              icon: Icons.save,
            ),
          ],
        ),
      ),
    );
  }

  void _openReview(BuildContext context) {
    final questions = generation.questionsJson
        .map((json) => GeneratedQuestion.fromJson(json))
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuestionReviewScreen(
          questions: questions,
          type: generation.type,
          difficulty: generation.difficulty,
          source: generation.sourceFile,
          sourceText: generation.sourceText,
        ),
      ),
    );
  }

  Future<void> _pickDeck(BuildContext context) async {
    final db = context.read<DatabaseProvider>();
    final decks = await db.deckRepository.getAllDecks();
    if (!context.mounted) return;

    if (decks.isEmpty) {
      await DialogService.showInfo(context, 'Create a deck first');
      return;
    }

    final selectedDeckId = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save to Deck'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return ListTile(
                title: Text(deck.name),
                onTap: () => Navigator.of(context).pop(deck.id),
              );
            },
          ),
        ),
      ),
    );

    if (selectedDeckId == null || !context.mounted) return;

    final questions = generation.questionsJson
        .map((json) => GeneratedQuestion.fromJson(json))
        .toList();
    final recentRepo = context.read<RecentGenerationRepository>();

    try {
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        final qType = QuestionValidationService.determineQuestionType(
          type: q.type,
          options: q.options,
          answer: q.answer,
        );
        final storedType = QuestionTypeHelper.fromExamQuestionType(qType);
        String answer;
        String? optionA, optionB, optionC, optionD, correctOption;
        String? enumerationItemsJson;
        switch (qType) {
          case QuestionType.multipleChoice:
            final options = q.options;
            final idx = q.correctAnswerIndex.clamp(0, options.length - 1);
            optionA = options.isNotEmpty ? options[0] : null;
            optionB = options.length > 1 ? options[1] : null;
            optionC = options.length > 2 ? options[2] : null;
            optionD = options.length > 3 ? options[3] : null;
            correctOption = QuestionTypeHelper.indexToLetter(idx);
            answer = options.isNotEmpty ? options[idx] : (q.answer ?? '');
            break;
          case QuestionType.enumeration:
            final items = EnumerationFormatter.splitItems(q.answer ?? '');
            enumerationItemsJson = QuestionTypeHelper.encodeEnumerationItems(items);
            answer = items.join(', ');
            break;
          case QuestionType.identification:
          case QuestionType.mixedFormat:
            answer = q.answer ?? '';
            break;
        }
        await db.flashcardRepository.createFlashcard(
          FlashcardsCompanion(
            question: drift.Value(q.question),
            answer: drift.Value(answer),
            deckId: drift.Value(selectedDeckId),
            order: drift.Value(i),
            questionType: drift.Value(storedType),
            optionA: drift.Value(optionA),
            optionB: drift.Value(optionB),
            optionC: drift.Value(optionC),
            optionD: drift.Value(optionD),
            correctOption: drift.Value(correctOption),
            enumerationItems: drift.Value(enumerationItemsJson),
            explanation: drift.Value(q.explanation),
          ),
        );
      }
      await db.deckRepository.updateDeckCardCount(selectedDeckId);
      await recentRepo.updateSavedDeckId(generation.id, selectedDeckId);
      db.refreshAll();
      if (!context.mounted) return;
      await DialogService.showSuccess(context, 'Saved ${questions.length} questions to deck');
    } catch (e) {
      if (context.mounted) {
        await DialogService.showError(context, 'Failed to save: $e');
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    context.read<RecentGenerationRepository>().deleteGeneration(generation.id);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
