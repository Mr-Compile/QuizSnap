import 'package:flutter/material.dart';
import '../../core/services/dialog_service.dart';

/// Backward-compatible wrapper for the new ConfirmationDialog.
/// 
/// This class maintains the old API for existing code while using the new
/// centered, Material 3-compliant dialog system internally.
/// 
/// New code should use DialogService.showConfirmation() directly.
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    // This is now a wrapper - the actual dialog is shown via the show method
    return const SizedBox.shrink();
  }

  static Future<bool> show({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    return await DialogService.showConfirmation(
      context,
      message ?? '',
      title: title,
      confirmAction: confirmText,
      cancelAction: cancelText,
      isDestructive: isDestructive,
    ) ?? false;
  }
}
