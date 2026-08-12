import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/notification_service.dart';
import '../../core/database/database.dart';
import '../../shared/widgets/formatted_study_text.dart';
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
        context.read<NotificationService>().showErrorTop('Error loading flashcard: $e');
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
                  Text(
                    'Question',
                    style: AppTheme.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
                    text: card.answer,
                    style: AppTheme.bodyMedium,
                  ),
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

  void _shareCard(Flashcard card) {
    final text = 'Question:\n${card.question}\n\nAnswer:\n${card.answer}';
    Share.share(text, subject: 'QuizSnap Flashcard');
  }

  void _editCard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditFlashcardScreen(flashcardId: widget.flashcardId),
      ),
    ).then((_) => _loadCard());
  }

  Future<void> _confirmDelete(Flashcard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flashcard'),
        content: const Text('Delete this flashcard?'),
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
      if (mounted) {
        context.read<NotificationService>().showSuccess('Flashcard deleted');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.read<NotificationService>().showErrorTop('Failed to delete: $e');
      }
    }
  }
}
