import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../core/models/backup.dart';
import '../../core/providers/export_provider.dart';
import '../../core/services/dialog_service.dart';
import 'create_backup_dialog.dart';
import 'backup_history_screen.dart';
import 'restore_confirmation_dialog.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  BackupSchedule? _schedule;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final exportProvider = context.read<ExportProvider>();
    final schedule = await exportProvider.getBackupSchedule();
    if (mounted) {
      setState(() {
        _schedule = schedule;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Backup & Restore'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Backup & Restore',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildAutomaticBackupSection(),
          const SizedBox(height: 24),
          _buildBackupHistory(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Create Backup',
                  icon: Icons.backup,
                  onPressed: _handleCreateBackup,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'View History',
                  icon: Icons.history,
                  isSecondary: true,
                  onPressed: _handleViewHistory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutomaticBackupSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Automatic Backup',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Switch(
                value: _schedule?.enabled ?? false,
                onChanged: _handleToggleAutoBackup,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_schedule?.enabled ?? false) ...[
            _buildScheduleDetail('Interval', '${_schedule?.intervalDays ?? 7} days'),
            const SizedBox(height: 8),
            _buildScheduleDetail(
              'Last Backup',
              _schedule?.lastBackupDate != null
                  ? _formatDateTime(_schedule!.lastBackupDate!)
                  : 'Never',
            ),
            const SizedBox(height: 8),
            _buildScheduleDetail(
              'Next Backup',
              _schedule?.nextBackupDate != null
                  ? _formatDateTime(_schedule!.nextBackupDate!)
                  : 'Not scheduled',
            ),
          ] else
            Text(
              'Automatic backup is disabled',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleDetail(String label, String value) {
    return Row(
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
    );
  }

  Widget _buildBackupHistory() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Backups',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: _handleViewHistory,
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<BackupMetadata>>(
            future: context.read<ExportProvider>().backupService.getBackupHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const EmptyState(
                  icon: Icons.backup_outlined,
                  title: 'No backups yet',
                  subtitle: 'Create your first backup to protect your data',
                );
              }

              final backups = snapshot.data!.take(3).toList();

              return Column(
                children: backups.map((backup) {
                  return _BackupListItem(
                    backup: backup,
                    onTap: () => _handleBackupAction(backup),
                    onRestore: () => _handleRestore(backup),
                    onDelete: () => _handleDelete(backup),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleCreateBackup() async {
    final result = await showDialog<BackupMetadata>(
      useRootNavigator: true,
      context: context,
      builder: (context) => const CreateBackupDialog(),
    );

    if (result != null && mounted) {
      await DialogService.showSuccess(context, 'Backup "${result.name}" created successfully');
      setState(() {});
    }
  }

  void _handleViewHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BackupHistoryScreen(),
      ),
    );
  }

  Future<void> _handleToggleAutoBackup(bool enabled) async {
    final intervalDays = _schedule?.intervalDays ?? 7;
    final newSchedule = BackupSchedule(
      enabled: enabled,
      intervalDays: intervalDays,
      lastBackupDate: _schedule?.lastBackupDate,
      nextBackupDate: enabled
          ? DateTime.now().add(Duration(days: intervalDays))
          : null,
    );

    await context.read<ExportProvider>().updateBackupSchedule(newSchedule);

    if (mounted) {
      setState(() {
        _schedule = newSchedule;
      });
    }
  }

  void _handleBackupAction(BackupMetadata backup) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Backup Details'),
              onTap: () {
                Navigator.pop(context);
                _showBackupDetails(backup);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore from Backup'),
              onTap: () {
                Navigator.pop(context);
                _handleRestore(backup);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Backup'),
              onTap: () {
                Navigator.pop(context);
                _handleDelete(backup);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupDetails(BackupMetadata backup) {
    showDialog(
      useRootNavigator: true,
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          backup.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Type', backup.typeDisplay),
              _detailRow('Status', backup.statusDisplay),
              _detailRow('Size', backup.fileSizeDisplay),
              _detailRow('Created', _formatDateTime(backup.createdAt)),
              _detailRow('Decks', '${backup.deckCount}'),
              _detailRow('Flashcards', '${backup.flashcardCount}'),
              _detailRow('Folders', '${backup.folderCount}'),
              _detailRow('Tags', '${backup.tagCount}'),
              if (backup.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Description',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  backup.description!,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _shareBackup(backup),
            child: const Text('Share'),
          ),
          TextButton(
            onPressed: () => _openBackup(backup),
            child: const Text('Open File'),
          ),
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
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Future<String?> _getBackupFilePath(BackupMetadata backup) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/backups/${backup.name}.json';
  }

  Future<void> _shareBackup(BackupMetadata backup) async {
    final filePath = await _getBackupFilePath(backup);
    if (filePath == null) return;
    try {
      await Share.shareXFiles([XFile(filePath)], text: 'QuizSnap backup: ${backup.name}');
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Could not share backup: $e');
      }
    }
  }

  Future<void> _openBackup(BackupMetadata backup) async {
    final filePath = await _getBackupFilePath(backup);
    if (filePath == null) return;
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done && mounted) {
        await DialogService.showError(context, 'Could not open backup: ${result.message}');
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Could not open backup: $e');
      }
    }
  }

  Future<void> _handleRestore(BackupMetadata backup) async {
    final confirmed = await showDialog<bool>(
      useRootNavigator: true,
      context: context,
      builder: (context) => RestoreConfirmationDialog(backup: backup),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<ExportProvider>().restoreBackup(backup.id);
        if (mounted) {
          await DialogService.showSuccess(context, 'Backup restored successfully');
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          await DialogService.showError(context, 'Failed to restore: $e');
        }
      }
    }
  }

  Future<void> _handleDelete(BackupMetadata backup) async {
    final confirmed = await showDialog<bool>(
      useRootNavigator: true,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text('Are you sure you want to delete "${backup.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<ExportProvider>().deleteBackup(backup.id);
        if (mounted) {
          await DialogService.showSuccess(context, 'Backup deleted');
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          await DialogService.showError(context, 'Failed to delete: $e');
        }
      }
    }
  }
}

class _BackupListItem extends StatelessWidget {
  final BackupMetadata backup;
  final VoidCallback onTap;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _BackupListItem({
    required this.backup,
    required this.onTap,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    backup.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${backup.typeDisplay} • ${backup.fileSizeDisplay}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
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
      ),
    );
  }

  Color _getStatusColor() {
    switch (backup.status) {
      case BackupStatus.completed:
        return AppTheme.bambooGreen600;
      case BackupStatus.failed:
        return AppTheme.red600;
      case BackupStatus.creating:
      case BackupStatus.restoring:
        return AppTheme.amber600;
      default:
        return AppTheme.slate600;
    }
  }

  IconData _getStatusIcon() {
    switch (backup.status) {
      case BackupStatus.completed:
        return Icons.check_circle;
      case BackupStatus.failed:
        return Icons.error;
      case BackupStatus.creating:
      case BackupStatus.restoring:
        return Icons.cloud_upload;
      default:
        return Icons.schedule;
    }
  }
}