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

  static Future<void> show({
    required BuildContext context,
    required int answeredCount,
    required int totalQuestions,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => SubmitConfirmationDialog(
        answeredCount: answeredCount,
        totalQuestions: totalQuestions,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final unansweredCount = totalQuestions - answeredCount;
    final hasUnanswered = unansweredCount > 0;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
      ),
      elevation: 0,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? AppTheme.spacing8 : AppTheme.spacing6,
        vertical: AppTheme.spacing6,
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? AppTheme.spacing8 : AppTheme.spacing4,
        vertical: AppTheme.spacing8,
      ),
      title: Row(
        children: [
          Icon(
            Icons.assignment_turned_in,
            color: colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Text(
            'Submit Exam?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: isTablet ? AppTheme.text2xl : AppTheme.textLg,
              fontWeight: AppTheme.fontSemiBold,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 520 : double.infinity,
        ),
        child: Column(
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
              colorScheme.primary,
            ),
            if (hasUnanswered) ...[
              const SizedBox(height: AppTheme.spacingMd),
              _buildStatCard(
                context,
                'Unanswered',
                '$unansweredCount/$totalQuestions',
                Icons.warning,
                colorScheme.error,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.onSurfaceVariant,
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
