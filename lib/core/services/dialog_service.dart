import 'package:flutter/material.dart';

/// Safe, root-navigator dialog feedback service.
///
/// Use instead of [ScaffoldMessenger] or inline [showDialog] calls that can
/// throw "No Overlay widget found" when called with an invalid or unmounted
/// [BuildContext].
///
/// * Every entry point checks `context.mounted` before and after the async gap.
/// * All dialogs use `useRootNavigator: true` to target the main app navigator.
/// * No global [BuildContext] is stored; callers pass a valid descendant context.
class DialogService {
  DialogService._();

  static Future<void> showSuccess(
    BuildContext context,
    String message, {
    String title = 'Success',
    VoidCallback? onAcknowledge,
  }) async {
    if (!context.mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    await _show(
      context: context,
      icon: Icons.check_circle_rounded,
      iconColor: colorScheme.primary,
      title: title,
      message: message,
      actionLabel: 'OK',
      onAction: onAcknowledge,
    );
  }

  static Future<void> showError(
    BuildContext context,
    String message, {
    String title = 'Error',
    VoidCallback? onAcknowledge,
  }) async {
    if (!context.mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    await _show(
      context: context,
      icon: Icons.error_outline,
      iconColor: colorScheme.error,
      title: title,
      message: message,
      actionLabel: 'OK',
      onAction: onAcknowledge,
    );
  }

  static Future<void> showWarning(
    BuildContext context,
    String message, {
    String title = 'Warning',
    VoidCallback? onAcknowledge,
  }) async {
    if (!context.mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    await _show(
      context: context,
      icon: Icons.warning_amber_rounded,
      iconColor: colorScheme.tertiary,
      title: title,
      message: message,
      actionLabel: 'OK',
      onAction: onAcknowledge,
    );
  }

  static Future<void> showInfo(
    BuildContext context,
    String message, {
    String title = 'Info',
    VoidCallback? onAcknowledge,
  }) async {
    if (!context.mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    await _show(
      context: context,
      icon: Icons.info_outline,
      iconColor: colorScheme.primary,
      title: title,
      message: message,
      actionLabel: 'OK',
      onAction: onAcknowledge,
    );
  }

  /// Friendly replacement for raw AI quota / token errors.
  static Future<void> showQuotaExceeded(BuildContext context) async {
    if (!context.mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    await _show(
      context: context,
      icon: Icons.hourglass_empty,
      iconColor: colorScheme.tertiary,
      title: 'AI Limit Reached',
      message:
          'You have used today\'s AI generation limit. You can try again tomorrow or ask the administrator for additional quota.',
      actionLabel: 'OK',
    );
  }

  static Future<void> _show({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String actionLabel,
    VoidCallback? onAction,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(icon, color: iconColor, size: 32),
          title: Text(
            title,
            style: Theme.of(dialogContext).textTheme.titleLarge,
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onAction?.call();
              },
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
    if (onAction != null && !context.mounted) return;
  }
}
