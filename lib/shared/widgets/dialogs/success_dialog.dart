import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'app_dialog.dart';

/// Success dialog with green icon and positive tone.
/// 
/// Example usage:
/// ```dart
/// await SuccessDialog.show(
///   context: context,
///   title: 'Moved to Trash',
///   message: 'The deck was moved to Trash and can be restored later.',
/// );
/// ```
class SuccessDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool barrierDismissible;

  const SuccessDialog({
    super.key,
    required this.title,
    this.message,
    this.actionLabel = 'OK',
    this.onAction,
    this.barrierDismissible = true,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    String? message,
    String actionLabel = 'OK',
    VoidCallback? onAction,
    bool barrierDismissible = true,
  }) async {
    if (!context.mounted) return;

    await AppDialog.show(
      context: context,
      title: title,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: AppTheme.emerald600,
      barrierDismissible: barrierDismissible,
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onAction?.call();
          },
          child: Text(actionLabel),
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
