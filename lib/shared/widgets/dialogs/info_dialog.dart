import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'app_dialog.dart';

/// Info dialog with blue icon and single dismiss action.
/// 
/// Example usage:
/// ```dart
/// await InfoDialog.show(
///   context: context,
///   title: 'Study Tip',
///   message: 'Review your flashcards daily for better retention.',
/// );
/// ```
class InfoDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool barrierDismissible;

  const InfoDialog({
    super.key,
    required this.title,
    this.message,
    this.actionLabel = 'Got It',
    this.onAction,
    this.barrierDismissible = true,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    String? message,
    String actionLabel = 'Got It',
    VoidCallback? onAction,
    bool barrierDismissible = true,
  }) async {
    if (!context.mounted) return;

    await AppDialog.show(
      context: context,
      title: title,
      message: message,
      icon: Icons.info_outline_rounded,
      iconColor: AppTheme.blue600,
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
