import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers/database_provider.dart';
import '../../core/providers/trash_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/database/database.dart';
import '../../core/utils/question_type_helper.dart';
import '../../shared/widgets/formatted_study_text.dart';
import '../../shared/widgets/question_type_chip.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import 'edit_flashcard_screen.dart';

/// Flashcard detail screen that displays question/answer, tags,
/// and provides edit, delete, and share actions.
class FlashcardDetailScreen extends StatefulWidget {
  final int flashcardId;
  final String? deckName;

  const FlashcardDetailScreen({
    super.key,
    required this.flashcardId,
    this.deckName,
  });

  @override
  State<FlashcardDetailScreen> createState() => _FlashcardDetailScreenState();
}

class _FlashcardDetailScreenState extends State<FlashcardDetailScreen> {
  Flashcard? _flashcard;
  List<Tag> _tags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
    final db = context.read<DatabaseProvider>();
    try {
      final card = await db.flashcardRepository.getFlashcardById(widget.flashcardId);
      final tags = await db.tagRepository.getTagsForFlashcard(widget.flashcardId);
      if (mounted) {
        setState(() {
          _flashcard = card;
          _tags = tags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await DialogService.showError(context, 'Error loading flashcard: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: widget.deckName ?? 'Flashcard'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final card = _flashcard;
    if (card == null) {
      return Scaffold(
        appBar: CustomAppBar(title: widget.deckName ?? 'Flashcard'),
        body: const Center(child: Text('Flashcard not found')),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.deckName ?? 'Flashcard',
        actions: [
          IconButton(
            icon: Icon(card.isFavorite ? Icons.bookmark : Icons.bookmark_border),
            color: card.isFavorite ? Theme.of(context).colorScheme.primary : null,
            onPressed: () => _toggleBookmark(card),
            tooltip: card.isFavorite ? 'Remove bookmark' : 'Bookmark card',
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: () => _duplicateCard(card),
            tooltip: 'Duplicate',
          ),
          IconButton(
            icon: const Icon(Icons.drive_file_move),
            onPressed: () => _moveCard(card),
            tooltip: 'Move',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareCard(card),
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCard,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(card),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question',
                        style: AppTheme.labelLarge.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      QuestionTypeChip(questionType: card.questionType),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  FormattedStudyText(
                    text: card.question,
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Answer',
                    style: AppTheme.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  FormattedStudyText(
                    text: QuestionTypeHelper.displayAnswer(card),
                    style: AppTheme.bodyMedium,
                  ),
                  if (card.explanation != null &&
                      card.explanation!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    const Divider(),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'Explanation',
                      style: AppTheme.labelLarge.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    FormattedStudyText(
                      text: card.explanation!,
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingMd),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tags',
                      style: AppTheme.labelLarge.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) => Chip(
                        label: Text(tag.name),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
            if (card.isFavorite) ...[
              const SizedBox(height: AppTheme.spacingMd),
              CustomCard(
                child: Row(
                  children: [
                    Icon(Icons.bookmark, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text('Bookmarked', style: AppTheme.labelLarge),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBookmark(Flashcard card) async {
    try {
      final db = context.read<DatabaseProvider>();
      await db.flashcardRepository.updateFlashcard(
        card.copyWith(isFavorite: !card.isFavorite),
      );
      if (mounted) {
        await DialogService.showSuccess(context, 
          card.isFavorite ? 'Bookmark removed' : 'Flashcard bookmarked',
        );
        _loadCard();
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Failed to bookmark: $e');
      }
    }
  }

  Future<void> _duplicateCard(Flashcard card) async {
    try {
      final db = context.read<DatabaseProvider>();
      await db.flashcardRepository.createFlashcard(
        FlashcardsCompanion(
          question: drift.Value('${card.question} (Copy)'),
          answer: drift.Value(QuestionTypeHelper.displayAnswer(card)),
          deckId: drift.Value(card.deckId),
          order: drift.Value(card.order + 1),
          questionType: drift.Value(card.questionType),
          optionA: drift.Value(card.optionA),
          optionB: drift.Value(card.optionB),
          optionC: drift.Value(card.optionC),
          optionD: drift.Value(card.optionD),
          correctOption: drift.Value(card.correctOption),
          enumerationItems: drift.Value(card.enumerationItems),
          explanation: drift.Value(card.explanation),
        ),
      );
      await db.deckRepository.updateDeckCardCount(card.deckId);
      if (mounted) {
        await DialogService.showSuccess(context, 'Flashcard duplicated');
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Failed to duplicate: $e');
      }
    }
  }

  void _shareCard(Flashcard card) {
    final text = 'Question:\n${card.question}\n\nAnswer:\n${QuestionTypeHelper.displayAnswer(card)}';
    Share.share(text, subject: 'QuizSnap Flashcard');
  }

  void _editCard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditFlashcardScreen(flashcardId: widget.flashcardId),
      ),
    ).then((_) => _loadCard());
  }

  void _moveCard(Flashcard card) {
    GoRouter.of(context).push(
      AppRoutes.moveFlashcards,
      extra: {
        'flashcardIds': [card.id],
        'sourceDeckId': card.deckId,
      },
    ).then((_) {
      if (mounted) _loadCard();
    });
  }

  Future<void> _confirmDelete(Flashcard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Trash'),
        content: const Text('Move this flashcard to Trash? You can restore it later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final db = context.read<DatabaseProvider>();
      await db.flashcardRepository.deleteFlashcard(card.id);
      db.refreshDecks();
      if (mounted) {
        context.read<TrashProvider>().load();
      }
      if (mounted) {
        await DialogService.showSuccess(context, 'Flashcard deleted');
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Failed to delete: $e');
      }
    }
  }
}
