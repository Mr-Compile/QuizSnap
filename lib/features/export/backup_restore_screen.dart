import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../core/models/backup.dart';
import '../../core/providers/export_provider.dart';
import 'create_backup_dialog.dart';
import 'backup_history_screen.dart';
import 'restore_confirmation_dialog.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  late ExportProvider _exportProvider;
  BackupSchedule? _schedule;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _exportProvider = context.read<ExportProvider>();

    final schedule = await _exportProvider.getBackupSchedule();
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
            const Text(
              'Automatic backup is disabled',
              style: TextStyle(color: Colors.grey),
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
            future: _exportProvider.backupService.getBackupHistory(),
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
      context: context,
      builder: (context) => const CreateBackupDialog(),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup "${result.name}" created successfully')),
      );
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

    await _exportProvider.updateBackupSchedule(newSchedule);

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
      context: context,
      builder: (context) => AlertDialog(
        title: Text(backup.name),
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
                Text(backup.description!),
              ],
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
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _handleRestore(BackupMetadata backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => RestoreConfirmationDialog(backup: backup),
    );

    if (confirmed == true && mounted) {
      try {
        await _exportProvider.restoreBackup(backup.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restored successfully')),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to restore: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleDelete(BackupMetadata backup) async {
    final confirmed = await showDialog<bool>(
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
        await _exportProvider.deleteBackup(backup.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup deleted')),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
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
        return Colors.green;
      case BackupStatus.failed:
        return Colors.red;
      case BackupStatus.creating:
      case BackupStatus.restoring:
        return Colors.orange;
      default:
        return Colors.grey;
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