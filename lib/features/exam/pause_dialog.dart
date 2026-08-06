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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.roundedLg),
      ),
      title: Row(
        children: [
          Icon(
            Icons.pause_circle_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: AppTheme.spacing4),
          const Text('Exam Paused'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your exam has been paused. You can resume or exit the exam.',
          ),
          const SizedBox(height: AppTheme.spacing6),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppTheme.roundedMd),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacing2),
                Expanded(
                  child: Text(
                    'Warning: If you exit, your progress will be lost.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
