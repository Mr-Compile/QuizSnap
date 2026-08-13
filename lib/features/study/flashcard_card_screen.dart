import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/flashcard_reveal_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../core/services/question_generation_service.dart';
import '../../core/database/database.dart';
import 'rate_card_bottom_sheet.dart';

class FlashcardCardScreen extends StatefulWidget {
  final List<Flashcard> flashcards;
  final int currentIndex;
  final Function(int) onCardRated;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Function()? onBookmark;
  final Function()? onDelete;
  final Function()? onRestore;

  const FlashcardCardScreen({
    super.key,
    required this.flashcards,
    required this.currentIndex,
    required this.onCardRated,
    this.onPrevious,
    this.onNext,
    this.onBookmark,
    this.onDelete,
    this.onRestore,
  });

  @override
  State<FlashcardCardScreen> createState() => _FlashcardCardScreenState();
}

class _FlashcardCardScreenState extends State<FlashcardCardScreen> {
  @override
  Widget build(BuildContext context) {
    final progress = '${widget.currentIndex + 1}/${widget.flashcards.length}';
    final currentCard = widget.flashcards[widget.currentIndex];
    final revealProvider = context.watch<FlashcardRevealProvider>();
    final isAnswerRevealed = revealProvider.isRevealed(currentCard.id);

    return Column(
      children: [
        Expanded(
          child: _buildFlashcard(context, currentCard, widget.currentIndex, isAnswerRevealed, revealProvider),
        ),
        _buildProgressIndicator(context, progress),
        _buildActionButtons(context, currentCard, isAnswerRevealed, revealProvider),
      ],
    );
  }

  Widget _buildFlashcard(
    BuildContext context,
    Flashcard flashcard,
    int index,
    bool isAnswerRevealed,
    FlashcardRevealProvider revealProvider,
  ) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                revealProvider.toggle(flashcard.id);
              },
              onHorizontalDragEnd: (details) => _handleSwipe(context, details, flashcard, isAnswerRevealed, revealProvider),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Card header with bookmark
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Card ${index + 1}',
                            style: AppTheme.labelSmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              flashcard.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                              color: flashcard.isFavorite
                                  ? AppTheme.amber500
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => _toggleBookmark(flashcard),
                            tooltip: flashcard.isFavorite ? 'Remove bookmark' : 'Bookmark',
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Question',
                                  style: AppTheme.labelMedium.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingMd),
                                Text(
                                  QuestionGenerationService.sanitizeText(flashcard.question),
                                  style: AppTheme.headlineSmall,
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: isAnswerRevealed ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: isAnswerRevealed ? null : 0,
                        child: Container(
                          width: double.infinity,
                          height: 2,
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    if (isAnswerRevealed) ...[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingLg),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Answer',
                                    style: AppTheme.labelMedium.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingMd),
                                  Text(
                                    QuestionGenerationService.sanitizeText(flashcard.answer),
                                    style: AppTheme.headlineSmall,
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          if (!isAnswerRevealed)
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                revealProvider.reveal(flashcard.id);
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Show Answer'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
        ],
      ),
    );
  }

  void _handleSwipe(
    BuildContext context,
    DragEndDetails details,
    Flashcard flashcard,
    bool isAnswerRevealed,
    FlashcardRevealProvider revealProvider,
  ) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity == 0) return;

    if (!isAnswerRevealed) {
      HapticFeedback.lightImpact();
      revealProvider.reveal(flashcard.id);
      return;
    }

    if (velocity > 200) {
      // Swipe right = Good
      HapticFeedback.mediumImpact();
      widget.onCardRated(3);
    } else if (velocity < -200) {
      // Swipe left = Again
      HapticFeedback.heavyImpact();
      widget.onCardRated(0);
    }
  }

  Widget _buildProgressIndicator(BuildContext context, String progress) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: (widget.currentIndex + 1) / widget.flashcards.length,
              backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Text(
            progress,
            style: AppTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Flashcard flashcard,
    bool isAnswerRevealed,
    FlashcardRevealProvider revealProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        children: [
          // Navigation buttons
          Row(
            children: [
              if (widget.onPrevious != null && widget.currentIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onPrevious,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              if (widget.onPrevious != null && widget.currentIndex > 0)
                const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: ElevatedButton(
                  onPressed: isAnswerRevealed ? () => _showRateBottomSheet(context) : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text('Rate Card'),
                ),
              ),
              if (widget.onNext != null && widget.currentIndex < widget.flashcards.length - 1) ...[
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onNext,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Action buttons
          if (widget.onDelete != null || widget.onRestore != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                if (widget.onDelete != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(flashcard),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (widget.onDelete != null && widget.onRestore != null)
                  const SizedBox(width: AppTheme.spacingSm),
                if (widget.onRestore != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onRestore,
                      icon: const Icon(Icons.restore),
                      label: const Text('Restore'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _toggleBookmark(Flashcard flashcard) async {
    try {
      final dbProvider = context.read<DatabaseProvider>();
      final updatedCard = flashcard.copyWith(isFavorite: !flashcard.isFavorite);
      await dbProvider.flashcardRepository.updateFlashcard(updatedCard);
      
      if (mounted) {
        setState(() {
          // Update the flashcard in the list
          final index = widget.flashcards.indexWhere((f) => f.id == flashcard.id);
          if (index != -1) {
            widget.flashcards[index] = updatedCard;
          }
        });
        
        await DialogService.showSuccess(
          context,
          updatedCard.isFavorite ? 'Card bookmarked' : 'Bookmark removed',
        );
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Failed to toggle bookmark: $e');
      }
    }
  }

  void _confirmDelete(Flashcard flashcard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: const Text('Are you sure you want to delete this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRateBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => RateCardBottomSheet(
        onRated: (quality) {
          Navigator.of(context).pop();
          widget.onCardRated(quality);
        },
      ),
    );
  }
}