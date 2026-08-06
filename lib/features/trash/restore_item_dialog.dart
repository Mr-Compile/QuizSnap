import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
    return AlertDialog(
      title: Text(
        'Restore $itemType',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      content: Text(
        'Are you sure you want to restore "$itemName"?',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRestore();
          },
          child: const Text('Restore'),
        ),
      ],
    );
  }

  static Future<bool> show({
    required BuildContext context,
    required String itemType,
    required String itemName,
    required VoidCallback onRestore,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => RestoreItemDialog(
        itemType: itemType,
        itemName: itemName,
        onRestore: onRestore,
      ),
    );
    return true;
  }
}
