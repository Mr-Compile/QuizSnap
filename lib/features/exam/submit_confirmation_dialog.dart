import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_button.dart';

class SubmitConfirmationDialog extends StatelessWidget {
  final int answeredCount;
  final int totalQuestions;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const SubmitConfirmationDialog({
    super.key,
    required this.answeredCount,
    required this.totalQuestions,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final unansweredCount = totalQuestions - answeredCount;
    final hasUnanswered = unansweredCount > 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      title: Row(
        children: [
          Icon(
            Icons.assignment_turned_in,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: AppTheme.spacingMd),
          const Text('Submit Exam?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you ready to submit your exam?',
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildStatCard(
            context,
            'Answered',
            '$answeredCount/$totalQuestions',
            Icons.check_circle,
            Theme.of(context).colorScheme.primary,
          ),
          if (hasUnanswered) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _buildStatCard(
              context,
              'Unanswered',
              '$unansweredCount/$totalQuestions',
              Icons.warning,
              Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.warningContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      'You have unanswered questions. Are you sure you want to submit?',
                      style: AppTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        CustomButton(
          text: 'Review Answers',
          onPressed: onCancel,
          isOutlined: true,
          icon: Icons.arrow_back,
        ),
        CustomButton(
          text: 'Submit',
          onPressed: onConfirm,
          icon: Icons.check,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  value,
                  style: AppTheme.titleMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
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
