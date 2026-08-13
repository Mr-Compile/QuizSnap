import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'app_dialog.dart';

/// Warning dialog with amber icon and confirm/cancel actions.
/// 
/// Example usage:
/// ```dart
/// final confirmed = await WarningDialog.show(
///   context: context,
///   title: 'Delete Deck',
///   message: 'This action cannot be undone.',
///   confirmAction: 'Delete',
///   cancelAction: 'Cancel',
/// );
/// ```
class WarningDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String confirmAction;
  final String cancelAction;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool barrierDismissible;

  const WarningDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmAction = 'Confirm',
    this.cancelAction = 'Cancel',
    this.onConfirm,
    this.onCancel,
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
    bool barrierDismissible = true,
  }) async {
    if (!context.mounted) return false;

    return await AppDialog.show<bool>(
      context: context,
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      iconColor: AppTheme.amber600,
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
