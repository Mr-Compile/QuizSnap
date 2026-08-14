import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/database/database.dart';
import '../../core/providers/flashcard_selection_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/question_type_helper.dart';
import 'custom_card.dart';
import 'question_type_chip.dart';

/// A reusable flashcard tile that supports multi-select.
///
/// Long-press enters selection mode and selects the card.
/// In selection mode, tap toggles the checkbox.
/// In normal mode, tap calls [onOpen].
class SelectableFlashcardTile extends StatelessWidget {
  final Flashcard flashcard;
  final VoidCallback onOpen;

  const SelectableFlashcardTile({
    super.key,
    required this.flashcard,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FlashcardSelectionProvider>(
      builder: (context, selection, child) {
        final isSelected = selection.isSelected(flashcard.id);

        return Semantics(
          button: true,
          label: 'Flashcard: ${flashcard.question}',
          onTapHint: selection.isSelectionMode ? 'Toggle selection' : 'Open flashcard',
          onLongPressHint: 'Select flashcard',
          child: GestureDetector(
            onTap: () {
              if (selection.isSelectionMode) {
                selection.toggle(flashcard.id);
              } else {
                onOpen();
              }
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              selection.toggle(flashcard.id);
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedScale(
            scale: isSelected ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: CustomCard(
              child: Row(
                children: [
                  if (selection.isSelectionMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => selection.toggle(flashcard.id),
                      semanticLabel: 'Select flashcard',
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                flashcard.question,
                                style: AppTheme.labelLarge,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            QuestionTypeChip(
                              questionType: flashcard.questionType,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          QuestionTypeHelper.displayAnswer(flashcard),
                          style: AppTheme.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Row(
                          children: [
                            Icon(
                              Icons.reviews,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: AppTheme.spacingXs),
                            Text(
                              '${flashcard.reviewCount} reviews',
                              style: AppTheme.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                            if (flashcard.isFavorite) ...[
                              const SizedBox(width: AppTheme.spacingSm),
                              Icon(
                                Icons.bookmark,
                                color: Theme.of(context).colorScheme.primary,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }
}
