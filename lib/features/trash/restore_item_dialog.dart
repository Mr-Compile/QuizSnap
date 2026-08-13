import 'package:flutter/material.dart';
import '../../core/services/dialog_service.dart';

/// Modern restore dialog using the new centered dialog system.
class RestoreItemDialog extends StatelessWidget {
  final String itemType;
  final String itemName;
  final VoidCallback onRestore;

  const RestoreItemDialog({
    super.key,
    required this.itemType,
    required this.itemName,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    // This is now a wrapper - the actual dialog is shown via the show method
    return const SizedBox.shrink();
  }

  static Future<bool> show({
    required BuildContext context,
    required String itemType,
    required String itemName,
    required VoidCallback onRestore,
  }) async {
    final confirmed = await DialogService.showConfirmation(
      context,
      'Are you sure you want to restore "$itemName"?',
      title: 'Restore $itemType',
      confirmAction: 'Restore',
      cancelAction: 'Cancel',
    );

    if (confirmed == true) {
      onRestore();
      return true;
    }
    return false;
  }
}
