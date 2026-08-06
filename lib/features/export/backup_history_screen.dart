import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../core/models/backup.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/backup_service.dart';
import '../../core/repositories/deck_repository.dart';
import '../../core/repositories/flashcard_repository.dart';
import '../../core/repositories/folder_repository.dart';
import '../../core/repositories/tag_repository.dart';
import 'restore_confirmation_dialog.dart';

class BackupHistoryScreen extends StatefulWidget {
  const BackupHistoryScreen({super.key});

  @override
  State<BackupHistoryScreen> createState() => _BackupHistoryScreenState();
}

class _BackupHistoryScreenState extends State<BackupHistoryScreen> {
  late BackupService _backupService;
  List<BackupMetadata> _backups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final database = context.read<AppDatabase>();
    _backupService = BackupService(
      database,
      DeckRepository(database),
      FlashcardRepository(database),
      FolderRepository(database),
      TagRepository(database),
    );

    await _loadBackups();
  }

  Future<void> _loadBackups() async {
    final backups = await _backupService.getBackupHistory();
    if (mounted) {
      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Backup History',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackups,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _backups.isEmpty
              ? const EmptyState(
                  icon: Icons.backup_outlined,
                  title: 'No backups found',
                  description: 'Create a backup to see it here',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _backups.length,
                  itemBuilder: (context, index) {
                    final backup = _backups[index];
                    return _BackupCard(
                      backup: backup,
                      onRestore: () => _handleRestore(backup),
                      onDelete: () => _handleDelete(backup),
                      onTap: () => _showBackupDetails(backup),
                    );
                  },
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
              if (backup.completedAt != null)
                _detailRow('Completed', _formatDateTime(backup.completedAt!)),
              _detailRow('Decks', '${backup.deckCount}'),
              _detailRow('Flashcards', '${backup.flashcardCount}'),
              _detailRow('Folders', '${backup.folderCount}'),
              _detailRow('Tags', '${backup.tagCount}'),
              if (backup.description != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleRestore(BackupMetadata backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => RestoreConfirmationDialog(backup: backup),
    );

    if (confirmed == true && mounted) {
      try {
        await _backupService.restoreBackup(backup.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restored successfully')),
          );
          await _loadBackups();
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
        await _backupService.deleteBackup(backup.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup deleted')),
          );
          await _loadBackups();
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

class _BackupCard extends StatelessWidget {
  final BackupMetadata backup;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _BackupCard({
    required this.backup,
    required this.onRestore,
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
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(),
              color: _getStatusColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backup.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildChip(backup.typeDisplay),
                    const SizedBox(width: 8),
                    _buildChip(backup.statusDisplay),
                    const SizedBox(width: 8),
                    Text(
                      backup.fileSizeDisplay,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${_formatDateTime(backup.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}