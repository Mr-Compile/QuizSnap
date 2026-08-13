import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'app_dialog.dart';

/// Error dialog with red icon and error tone.
/// 
/// Example usage:
/// ```dart
/// await ErrorDialog.show(
///   context: context,
///   title: 'AI Limit Reached',
///   message: 'You have reached today\'s AI generation limit.',
///   primaryAction: 'Try Again',
///   secondaryAction: 'Close',
/// );
/// ```
class ErrorDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String primaryAction;
  final String secondaryAction;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final bool barrierDismissible;

  const ErrorDialog({
    super.key,
    required this.title,
    this.message,
    this.primaryAction = 'Try Again',
    this.secondaryAction = 'Close',
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.barrierDismissible = true,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    String? message,
    String primaryAction = 'Try Again',
    String secondaryAction = 'Close',
    VoidCallback? onPrimaryAction,
    VoidCallback? onSecondaryAction,
    bool barrierDismissible = true,
  }) async {
    if (!context.mounted) return;

    await AppDialog.show(
      context: context,
      title: title,
      message: message,
      icon: Icons.error_outline_rounded,
      iconColor: AppTheme.red600,
      barrierDismissible: barrierDismissible,
      actions: [
        if (secondaryAction.isNotEmpty)
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onSecondaryAction?.call();
            },
            child: Text(secondaryAction),
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onPrimaryAction?.call();
          },
          child: Text(primaryAction),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // This is for backward compatibility - use show() method instead
    return const SizedBox.shrink();
  }
}
