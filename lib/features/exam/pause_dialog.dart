import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_button.dart';

class PauseDialog extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onExit;

  const PauseDialog({
    super.key,
    required this.onResume,
    required this.onExit,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onResume,
    required VoidCallback onExit,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => PauseDialog(
        onResume: onResume,
        onExit: onExit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

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
            Icons.pause_circle_outline,
            color: colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Text(
            'Exam Paused',
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
              'Your exam has been paused. You can resume or exit the exam.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppTheme.roundedMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      'Warning: If you exit, your progress will be lost.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        CustomButton(
          text: 'Exit Exam',
          onPressed: onExit,
          isSecondary: true,
          isOutlined: true,
        ),
        CustomButton(
          text: 'Resume',
          onPressed: onResume,
          icon: Icons.play_arrow,
        ),
      ],
    );
  }
}
