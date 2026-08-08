import 'package:flutter/material.dart';

enum RegenerationOption {
  regenerateAll,
  regenerateSelected,
  keepApprovedReplaceRejected,
}

class RegenerationOptionsBottomSheet extends StatelessWidget {
  final int totalQuestions;
  final int approvedCount;
  final int rejectedCount;
  final Function(RegenerationOption) onOptionSelected;

  const RegenerationOptionsBottomSheet({
    super.key,
    required this.totalQuestions,
    required this.approvedCount,
    required this.rejectedCount,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Text(
            'Regenerate Questions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how to regenerate the questions',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          
          // Statistics
          _buildStatistics(context),
          const SizedBox(height: 24),
          
          // Options
          _buildOption(
            context,
            title: 'Regenerate All Questions',
            description: 'Replace all questions with new ones',
            icon: Icons.refresh,
            onTap: () => onOptionSelected(RegenerationOption.regenerateAll),
          ),
          const SizedBox(height: 12),
          
          _buildOption(
            context,
            title: 'Regenerate Selected Only',
            description: 'Replace only the questions you select',
            icon: Icons.check_circle_outline,
            onTap: () => onOptionSelected(RegenerationOption.regenerateSelected),
          ),
          const SizedBox(height: 12),
          
          if (rejectedCount > 0)
            _buildOption(
              context,
              title: 'Keep Approved, Replace Rejected',
              description: 'Keep $approvedCount approved, replace $rejectedCount rejected',
              icon: Icons.swap_horiz,
              onTap: () => onOptionSelected(RegenerationOption.keepApprovedReplaceRejected),
            ),
          
          const SizedBox(height: 16),
          
          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            label: 'Total',
            value: totalQuestions,
            color: Theme.of(context).colorScheme.primary,
          ),
          _buildStatItem(
            context,
            label: 'Approved',
            value: approvedCount,
            color: Colors.green,
          ),
          _buildStatItem(
            context,
            label: 'Rejected',
            value: rejectedCount,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required int value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}