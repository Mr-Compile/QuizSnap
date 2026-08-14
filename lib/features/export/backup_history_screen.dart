import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../core/models/backup_enhanced.dart';
import '../../core/providers/backup_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/dialog_service.dart';

class BackupHistoryScreen extends ConsumerStatefulWidget {
  const BackupHistoryScreen({super.key});

  @override
  ConsumerState<BackupHistoryScreen> createState() =>
      _BackupHistoryScreenState();
}

class _BackupHistoryScreenState extends ConsumerState<BackupHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    // List actual .db backup files (newest first). The provider resolves the
    // active folder (default or custom SAF tree) internally.
    final backupsAsync = ref.watch(backupFilesProvider(null));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Backup History',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(backupFilesProvider(null)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(backupFilesProvider(null));
        },
        child: backupsAsync.when(
          data: (backups) {
            if (backups.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.backup_outlined,
                    title: 'No backups found',
                    subtitle: 'Create a backup to see it here',
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: backups.length,
              itemBuilder: (context, index) {
                final backup = backups[index];
                return _BackupFileCard(
                  backup: backup,
                  onRestore: () => _handleRestore(backup),
                  onShare: () => _handleShare(backup),
                  onDelete: () => _handleDelete(backup),
                  onTap: () => _showBackupDetails(backup),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load backups',
                subtitle: 'Pull down to refresh. $e',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBackupDetails(BackupFileModel backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(backup.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('File', backup.fileName),
              _detailRow('Size', backup.fileSizeDisplay),
              _detailRow('Created', _formatDateTime(backup.createdAt)),
              _detailRow('Type',
                  backup.isDbBackup ? 'SQLite database (.db)' : 'Legacy backup'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  Future<void> _handleRestore(BackupFileModel backup) async {
    final filePath = backup.filePath;

    // SAF-backed files must be cached locally first.
    String localPath = filePath;
    final treeUri = await ref.read(customBackupTreeUriProvider.future);
    if (treeUri != null && filePath.startsWith(treeUri)) {
      try {
        localPath = await ref
            .read(backupServiceProvider)
            .cacheSafFileForRestore(treeUri: treeUri, fileName: backup.fileName);
      } catch (e) {
        if (mounted) {
          await DialogService.showError(context, 'Failed to access backup: $e');
        }
        return;
      }
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Text(
          'Restore from "${backup.fileName}"? This will replace your current database. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _RestoringDialog(),
    );

    final newDb = await ref
        .read(backupOperationProvider.notifier)
        .restoreFromDbFile(localPath);

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (newDb != null && mounted) {
      // Adopt the new database on the Provider-package side too.
      context.read<DatabaseProvider>().reopenDatabase(newDatabase: newDb);
      context.read<DatabaseProvider>().refreshDecks();
      context.read<DatabaseProvider>().refreshAnalytics();

      ref.invalidate(backupFilesProvider(null));
      ref.invalidate(backupHistoryProvider);

      await DialogService.showSuccess(
        context,
        'Your data has been restored successfully.',
        title: 'Restore Complete',
      );
    } else if (mounted) {
      final err = ref.read(backupOperationProvider).errorMessage;
      await DialogService.showError(
        context,
        err ?? 'The restore could not be completed. Please try again.',
        title: 'Restore Failed',
      );
    }
  }

  Future<void> _handleShare(BackupFileModel backup) async {
    try {
      final success = await ref
          .read(backupOperationProvider.notifier)
          .shareBackup(backup.filePath);
      if (!success && mounted) {
        await DialogService.showError(context, 'Failed to open share dialog');
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Failed to share: $e');
      }
    }
  }

  Future<void> _handleDelete(BackupFileModel backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text('Are you sure you want to delete "${backup.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(backupOperationProvider.notifier)
            .deleteBackupFile(backup.filePath);
        if (mounted) {
          ref.invalidate(backupFilesProvider(null));
          await DialogService.showSuccess(context, 'Backup deleted');
        }
      } catch (e) {
        if (mounted) {
          await DialogService.showError(context, 'Failed to delete: $e');
        }
      }
    }
  }
}

class _BackupFileCard extends StatelessWidget {
  final BackupFileModel backup;
  final VoidCallback onRestore;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _BackupFileCard({
    required this.backup,
    required this.onRestore,
    required this.onShare,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.storage,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backup.fileName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildChip(context, backup.fileSizeDisplay),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _formatDateTime(backup.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: onShare,
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: onRestore,
            tooltip: 'Restore',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }
}

class _RestoringDialog extends StatelessWidget {
  const _RestoringDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                'Restoring backup…',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
