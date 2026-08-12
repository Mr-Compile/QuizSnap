import 'package:flutter/material.dart';
import '../../core/database/database.dart';
import '../../core/providers/flashcard_selection_provider.dart';
import '../../core/theme/app_theme.dart';

/// Right-side preview pane for tablet multi-selection.
///
/// Shows the selected flashcards and quick batch actions.
class SelectionPreviewPane extends StatelessWidget {
  final List<Flashcard> flashcards;
  final FlashcardSelectionProvider selection;
  final VoidCallback onMove;
  final VoidCallback onDelete;
  final VoidCallback onBookmark;

  const SelectionPreviewPane({
    super.key,
    required this.flashcards,
    required this.selection,
    required this.onMove,
    required this.onDelete,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCards = flashcards.where((c) => selection.isSelected(c.id)).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          left: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Selection',
            style: AppTheme.labelLarge,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '${selection.selectedCount} selected',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Wrap(
            spacing: AppTheme.spacingSm,
            children: [
              FilledButton.icon(
                onPressed: selection.hasSelection ? onMove : null,
                icon: const Icon(Icons.drive_file_move, size: 18),
                label: const Text('Move'),
              ),
              FilledButton.tonalIcon(
                onPressed: selection.hasSelection ? onDelete : null,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
              OutlinedButton.icon(
                onPressed: selection.hasSelection ? onBookmark : null,
                icon: const Icon(Icons.bookmark, size: 18),
                label: const Text('Bookmark'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          if (selectedCards.isEmpty)
            Center(
              child: Text(
                'Select flashcards to see a preview',
                style: AppTheme.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedCards.length,
              itemBuilder: (context, index) {
                final card = selectedCards[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.question,
                          style: AppTheme.labelMedium,
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          card.answer,
                          style: AppTheme.bodySmall.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
