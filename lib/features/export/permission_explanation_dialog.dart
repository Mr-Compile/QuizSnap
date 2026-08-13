import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../shared/widgets/custom_button.dart';

class PermissionExplanationDialog extends StatelessWidget {
  final String permissionType;
  final String explanation;
  final VoidCallback onGrantAccess;
  final VoidCallback onNotNow;

  const PermissionExplanationDialog({
    super.key,
    required this.permissionType,
    required this.explanation,
    required this.onGrantAccess,
    required this.onNotNow,
  });

  static Future<bool?> showStoragePermissionDialog(
    BuildContext context, {
    VoidCallback? onOpenSettings,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => PermissionExplanationDialog(
        permissionType: 'Storage Access',
        explanation: 'QuizSnap needs access to your device storage to save and load backup files. This allows you to:',
        onGrantAccess: () async {
          Navigator.pop(context, true);
          final status = await Permission.storage.request();
          if (status.isPermanentlyDenied && onOpenSettings != null) {
            onOpenSettings();
          }
        },
        onNotNow: () => Navigator.pop(context, false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.folder_open,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Permission Required',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              permissionType,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(explanation),
            const SizedBox(height: 16),
            _buildPermissionReasons(context),
            const SizedBox(height: 16),
            _buildPrivacyNote(context),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onNotNow,
          child: const Text('Not Now'),
        ),
        CustomButton(
          text: 'Grant Access',
          onPressed: onGrantAccess,
        ),
      ],
    );
  }

  Widget _buildPermissionReasons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReasonItem(context, Icons.save_alt, 'Save backups to any location'),
          _buildReasonItem(context, Icons.folder_open, 'Load backups from any location'),
          _buildReasonItem(context, Icons.share, 'Share backup files with other apps'),
          _buildReasonItem(context, Icons.cloud_sync, 'Sync with cloud storage services'),
        ],
      ),
    );
  }

  Widget _buildReasonItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.privacy_tip,
            color: Theme.of(context).colorScheme.secondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your data stays on your device. We only access storage when you explicitly choose to save or load backup files.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class PermanentlyDeniedDialog extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const PermanentlyDeniedDialog({
    super.key,
    required this.onOpenSettings,
  });

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => PermanentlyDeniedDialog(
        onOpenSettings: () {
          Navigator.pop(context);
          openAppSettings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.block,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Permission Permanently Denied',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You have previously denied storage permission. To use backup features, you need to enable this permission in your device settings.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.tertiary),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.tertiary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Go to Settings > Apps > QuizSnap > Permissions to enable storage access.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onOpenSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: const Text('Open Settings'),
        ),
      ],
    );
  }
}
