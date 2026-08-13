import 'package:flutter/material.dart';
import 'app_dialog.dart';

/// Confirmation dialog with neutral icon and destructive action support.
/// 
/// Example usage:
/// ```dart
/// final confirmed = await ConfirmationDialog.show(
///   context: context,
///   title: 'Delete Deck',
///   message: 'Are you sure you want to delete this deck? This action cannot be undone.',
///   confirmAction: 'Delete',
///   cancelAction: 'Cancel',
///   isDestructive: true,
/// );
/// ```
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String confirmAction;
  final String cancelAction;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final bool barrierDismissible;

  const ConfirmationDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmAction = 'Confirm',
    this.cancelAction = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.barrierDismissible = true,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    String? message,
    String confirmAction = 'Confirm',
    String cancelAction = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
    bool barrierDismissible = true,
  }) async {
    if (!context.mounted) return false;

    final colorScheme = Theme.of(context).colorScheme;

    return await AppDialog.show<bool>(
      context: context,
      title: title,
      message: message,
      icon: Icons.help_outline_rounded,
      iconColor: isDestructive ? colorScheme.error : colorScheme.primary,
      barrierDismissible: barrierDismissible,
      actions: [
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Text(cancelAction),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          child: Text(confirmAction),
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
