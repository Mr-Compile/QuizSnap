import 'package:flutter/material.dart';
import '../../core/database/database.dart';
import '../../core/providers/flashcard_selection_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';

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
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppTheme.spacingLg),
          Expanded(
            child: selection.selectedIds.isEmpty
                ? _buildEmptySelectionState(context)
                : _buildPreviewContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selection Preview',
          style: AppTheme.headlineSmall,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          '${selection.selectedCount} card(s) selected',
          style: AppTheme.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySelectionState(BuildContext context) {
    return EmptyState(
      icon: Icons.check_circle_outline,
      title: 'No cards selected',
      subtitle: 'Select flashcards from the list to preview and perform batch actions',
    );
  }

  Widget _buildPreviewContent(BuildContext context) {
    final selectedFlashcards = flashcards
        .where((card) => selection.selectedIds.contains(card.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedFlashcards.isNotEmpty) ...[
          _buildSelectedCardsPreview(context, selectedFlashcards),
          const SizedBox(height: AppTheme.spacingLg),
        ],
        _buildBatchActions(context),
        const SizedBox(height: AppTheme.spacingLg),
        _buildSelectionSummary(context),
      ],
    );
  }

  Widget _buildSelectedCardsPreview(BuildContext context, List<Flashcard> selectedCards) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Cards (${selectedCards.length})',
            style: AppTheme.labelLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...selectedCards.take(3).map((card) => _buildMiniCardPreview(context, card)),
          if (selectedCards.length > 3) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              '...and ${selectedCards.length - 3} more',
              style: AppTheme.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniCardPreview(BuildContext context, Flashcard card) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.question,
            style: AppTheme.labelMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            card.answer,
            style: AppTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBatchActions(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Batch Actions',
            style: AppTheme.labelLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            children: [
              _buildActionButton(
                context,
                'Move to Deck',
                Icons.drive_file_move,
                onMove,
              ),
              _buildActionButton(
                context,
                'Bookmark',
                Icons.bookmark,
                onBookmark,
              ),
              _buildActionButton(
                context,
                'Delete',
                Icons.delete_outline,
                onDelete,
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDestructive
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            const SizedBox(width: AppTheme.spacingXs),
            Text(
              label,
              style: AppTheme.labelSmall.copyWith(
                color: isDestructive
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSummary(BuildContext context) {
    final selectedFlashcards = flashcards
        .where((card) => selection.selectedIds.contains(card.id))
        .toList();
    
    final bookmarkedCount = selectedFlashcards.where((card) => card.isFavorite).length;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selection Summary',
            style: AppTheme.labelLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildSummaryRow(
            context,
            'Total Selected',
            '${selection.selectedCount}',
          ),
          _buildSummaryRow(
            context,
            'Bookmarked',
            '$bookmarkedCount',
          ),
          _buildSummaryRow(
            context,
            'Ready for Action',
            'Yes',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}