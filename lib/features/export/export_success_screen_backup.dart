import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/app_bar.dart';
import '../../core/models/backup_enhanced.dart';
import '../../core/providers/backup_provider.dart';

class ExportSuccessScreenBackup extends ConsumerWidget {
  final BackupFileModel backupFile;

  const ExportSuccessScreenBackup({
    super.key,
    required this.backupFile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Backup Created',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSuccessCard(context),
          const SizedBox(height: 16),
          _buildFilePathCard(context, ref),
          const SizedBox(height: 16),
          _buildBackupDetailsCard(context),
          const SizedBox(height: 24),
          _buildActionButtons(context, ref),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context) {
    return CustomCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backup Created Successfully',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your data has been backed up securely',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePathCard(BuildContext context, WidgetRef ref) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder_open,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Backup Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backupFile.filePath,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPathActionButton(
                  context,
                  ref,
                  Icons.folder,
                  'Open Folder',
                  () => _openFolder(context, ref),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPathActionButton(
                  context,
                  ref,
                  Icons.copy,
                  'Copy Path',
                  () => _copyPath(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPathActionButton(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildBackupDetailsCard(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backup Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(context, 'File Name', backupFile.fileName),
          _buildDetailRow(context, 'File Size', backupFile.fileSizeDisplay),
          _buildDetailRow(context, 'Created', _formatDateTime(backupFile.createdAt)),
          _buildDetailRow(context, 'Type', backupFile.metadata.typeDisplay),
          _buildDetailRow(context, 'Decks', '${backupFile.metadata.deckCount}'),
          _buildDetailRow(context, 'Flashcards', '${backupFile.metadata.flashcardCount}'),
          _buildDetailRow(context, 'Folders', '${backupFile.metadata.folderCount}'),
          _buildDetailRow(context, 'Tags', '${backupFile.metadata.tagCount}'),
          if (backupFile.metadata.description != null) ...[
            const SizedBox(height: 8),
            Text(
              'Description',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              backupFile.metadata.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        CustomButton(
          text: 'Share Backup',
          icon: Icons.share,
          onPressed: () => _shareBackup(context, ref),
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Done',
          isSecondary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Future<void> _openFolder(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(backupOperationProvider.notifier).openBackupLocation(backupFile.filePath);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open folder: $e')),
        );
      }
    }
  }

  Future<void> _copyPath(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: backupFile.filePath));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Path copied to clipboard')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to copy path: $e')),
        );
      }
    }
  }

  Future<void> _shareBackup(BuildContext context, WidgetRef ref) async {
    try {
      final success = await ref.read(backupOperationProvider.notifier).shareBackup(backupFile.filePath);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Share dialog opened')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to open share dialog')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }
}
