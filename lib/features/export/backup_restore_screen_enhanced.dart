import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../core/models/backup_enhanced.dart';
import '../../core/providers/backup_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/navigation/app_routes.dart';
import 'import_preview_screen.dart';
import 'change_backup_folder_screen.dart';
import 'schedule_settings_dialog.dart';
import '../../core/services/dialog_service.dart';

class BackupRestoreScreenEnhanced extends ConsumerStatefulWidget {
  const BackupRestoreScreenEnhanced({super.key});

  @override
  ConsumerState<BackupRestoreScreenEnhanced> createState() => _BackupRestoreScreenEnhancedState();
}

class _BackupRestoreScreenEnhancedState extends ConsumerState<BackupRestoreScreenEnhanced> {
  bool _isCreatingBackup = false;

  @override
  Widget build(BuildContext context) {
    final backupScheduleAsync = ref.watch(backupScheduleProvider);
    final recentBackupsAsync = ref.watch(recentBackupsProvider);
    final customPathAsync = ref.watch(customBackupPathProvider);
    final backupHistoryAsync = ref.watch(backupHistoryProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Backup & Restore',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBackupStatus(backupHistoryAsync),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildImportSection(),
          const SizedBox(height: 24),
          _buildAutomaticBackupSection(backupScheduleAsync),
          const SizedBox(height: 24),
          _buildRecentBackups(recentBackupsAsync),
          const SizedBox(height: 24),
          _buildCurrentBackupFolder(customPathAsync),
        ],
      ),
    );
  }

  Widget _buildBackupStatus(AsyncValue<List<BackupMetadata>> historyAsync) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assessment_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Backup Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          historyAsync.when(
            data: (history) {
              final completed = history.where((b) => b.status == BackupStatus.completed).toList();
              final lastBackup = completed.isNotEmpty ? completed.last : null;
              final totalDecks = completed.fold<int>(0, (sum, b) => sum + b.deckCount);
              final totalFlashcards = completed.fold<int>(0, (sum, b) => sum + b.flashcardCount);

              return Column(
                children: [
                  _buildStatusRow(
                    'Total Backups',
                    '${completed.length}',
                    Icons.backup_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    'Last Backup',
                    lastBackup != null ? _formatDateTime(lastBackup.createdAt) : 'Never',
                    Icons.schedule,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    'Data Protected',
                    '$totalDecks decks, $totalFlashcards flashcards',
                    Icons.shield_outlined,
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Error loading backup status'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
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

  Widget _buildQuickActions() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Backup',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Backups are stored safely inside QuizSnap on your device. Use Share Backup if you want to save a copy to Downloads, Files, or cloud storage.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: _isCreatingBackup ? 'Creating...' : 'Create Backup Now',
            icon: Icons.backup,
            onPressed: _isCreatingBackup ? null : _handleCreateBackup,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBackupFolder(AsyncValue<String?> customPathAsync) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.folder_open,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Storage Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          customPathAsync.when(
            data: (path) => _buildPathDisplay(path),
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const Text('Error loading path'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Change Folder'),
                  onPressed: _handleChangeFolder,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.folder, size: 18),
                  label: const Text('Open Folder'),
                  onPressed: _handleOpenFolder,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPathDisplay(String? path) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            path == null ? Icons.smartphone : Icons.create_new_folder,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              path ?? 'Using default app storage',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomaticBackupSection(AsyncValue<BackupSchedule> scheduleAsync) {
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
              scheduleAsync.when(
                data: (schedule) => Switch(
                  value: schedule.enabled,
                  onChanged: (value) => _handleToggleAutoBackup(value, schedule),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          scheduleAsync.when(
            data: (schedule) => _buildScheduleDetails(schedule),
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const Text('Error loading schedule'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDetails(BackupSchedule schedule) {
    if (!schedule.enabled) {
      return Text(
        'Automatic backup is disabled',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      children: [
        _buildScheduleDetail('Frequency', schedule.frequencyDisplay),
        const SizedBox(height: 8),
        _buildScheduleDetail('Retention', schedule.retentionDisplay),
        const SizedBox(height: 8),
        _buildScheduleDetail(
          'Last Backup',
          schedule.lastBackupDate != null
              ? _formatDateTime(schedule.lastBackupDate!)
              : 'Never',
        ),
        const SizedBox(height: 8),
        _buildScheduleDetail(
          'Next Backup',
          schedule.nextBackupDate != null
              ? _formatDateTime(schedule.nextBackupDate!)
              : 'Not scheduled',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.settings, size: 18),
          label: const Text('Configure Schedule'),
          onPressed: _showScheduleSettings,
        ),
      ],
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

  Widget _buildRecentBackups(AsyncValue<List<BackupMetadata>> backupsAsync) {
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
                onPressed: _handleViewAllBackups,
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          backupsAsync.when(
            data: (backups) {
              if (backups.isEmpty) {
                return const EmptyState(
                  icon: Icons.backup_outlined,
                  title: 'No backups yet',
                  subtitle: 'Create your first backup to protect your data',
                );
              }

              return Column(
                children: backups.take(3).map((backup) {
                  return _BackupListItem(
                    backup: backup,
                    onTap: () => _showBackupDetails(backup),
                    onRestore: () => _handleRestore(backup),
                    onDelete: () => _handleDelete(backup),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Error loading backups'),
          ),
        ],
      ),
    );
  }

  Widget _buildImportSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Import from File',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Select a .quizsnap or .json backup file from any location on your device.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Select Backup File',
            icon: Icons.file_open,
            isSecondary: true,
            onPressed: _handleImportBackup,
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreateBackup() async {
    await _proceedWithBackupCreation();
  }

  Future<void> _proceedWithBackupCreation() async {
    setState(() => _isCreatingBackup = true);

    final customPath = await ref.read(customBackupPathProvider.future);

    final result = await ref.read(backupOperationProvider.notifier).exportBackup(
          name: 'quizsnap_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
          description: 'Manual backup',
          customPath: customPath,
        );

    if (mounted) {
      setState(() => _isCreatingBackup = false);
    }

    if (result != null && mounted) {
      await _showBackupSuccessDialog(result);
    } else if (mounted) {
      await DialogService.showError(
        context,
        'The backup could not be created. Please check available storage.',
        title: 'Backup Failed',
      );
    }
  }

  Future<void> _showBackupSuccessDialog(BackupFileModel result) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Backup Created'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your backup was saved successfully.'),
              const SizedBox(height: 16),
              _detailRow('File', result.fileName),
              const SizedBox(height: 8),
              _detailRow('Location', result.filePath),
              const SizedBox(height: 8),
              _detailRow('Size', result.fileSizeDisplay),
            ],
          ),
        ),
        actions: [
          OverflowBar(
            spacing: 8,
            overflowSpacing: 8,
            overflowAlignment: OverflowBarAlignment.end,
            overflowDirection: VerticalDirection.down,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Open Folder'),
                onPressed: () {
                  Navigator.pop(context);
                  _handleOpenFolder();
                },
              ),
              FilledButton.icon(
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                onPressed: () {
                  Navigator.pop(context);
                  _shareBackup(result.filePath);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareBackup(String filePath) async {
    try {
      final success = await ref.read(backupOperationProvider.notifier).shareBackup(filePath);
      if (!success && mounted) {
        await DialogService.showError(context, 'Failed to open share dialog');
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Failed to share: $e');
      }
    }
  }

  Future<void> _handleImportBackup() async {
    await _proceedWithFileSelection();
  }

  Future<void> _proceedWithFileSelection() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['quizsnap', 'json'],
        dialogTitle: 'Select Backup File',
        lockParentWindow: true,
        withData: false,
      );

      if (result != null && result.files.single.path != null && mounted) {
        final filePath = result.files.single.path!;

        // Validate file exists
        final file = File(filePath);
        if (!await file.exists()) {
          if (mounted) {
            await DialogService.showError(context, 'Selected file does not exist');
          }
          return;
        }

        // Navigate to import preview
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImportPreviewScreen(filePath: filePath),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Failed to select file: $e');
      }
    }
  }

  Future<void> _handleChangeFolder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangeBackupFolderScreen(),
      ),
    );

    if (result == true && mounted) {
      await DialogService.showSuccess(context, 'Backup folder changed');
    }
  }

  Future<void> _handleOpenFolder() async {
    final customPath = await ref.read(customBackupPathProvider.future);
    final backupService = ref.read(backupServiceProvider);
    final directory = customPath != null 
        ? Directory(customPath)
        : await backupService.getDefaultBackupDirectory();

    try {
      final success = await ref.read(backupOperationProvider.notifier).openBackupFolder(directory.path);
      if (!success && mounted) {
        await _showOpenFolderFallbackDialog(directory.path);
      }
    } catch (e) {
      if (mounted) {
        await _showOpenFolderFallbackDialog(directory.path);
      }
    }
  }

  Future<void> _showOpenFolderFallbackDialog(String folderPath) async {
    await DialogService.showInfo(
      context,
      Platform.isAndroid
          ? 'Your backup is saved in Android/data/${'com.quizsnap.quizsnap'}/files/QuizSnap/Backups. Use Share Backup to save it to Downloads, Google Drive, or another location.'
          : 'Your backup is saved in the app\'s Documents folder. You can access it through the Files app or by sharing it.',
      title: 'Backup Location',
    );
  }

  Future<void> _handleToggleAutoBackup(bool enabled, BackupSchedule currentSchedule) async {
    final newSchedule = currentSchedule.copyWith(enabled: enabled);
    await ref.read(backupOperationProvider.notifier).updateBackupSchedule(newSchedule);
  }

  void _showScheduleSettings() async {
    final currentSchedule = await ref.read(backupScheduleProvider.future);
    
    if (!mounted) return;
    
    final result = await showDialog<BackupSchedule>(
      context: context,
      builder: (context) => ScheduleSettingsDialog(
        currentSchedule: currentSchedule,
      ),
    );
    
    if (result != null && mounted) {
      await ref.read(backupOperationProvider.notifier).updateBackupSchedule(result);
      if (mounted) {
        await DialogService.showSuccess(context, 'Schedule settings updated');
      }
    }
  }

  void _handleViewAllBackups() {
    GoRouter.of(context).push(AppRoutes.backupHistory);
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

  Future<void> _handleRestore(BackupMetadata backup) async {
    if (backup.filePath == null) {
      await DialogService.showWarning(context, 'Backup file path not available');
      return;
    }

    try {
      // Navigate to import preview for validation and restore
      if (mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => ImportPreviewScreen(filePath: backup.filePath!),
          ),
        );

        if (result == true && mounted) {
          _refreshAllProviders();
        }
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Failed to load backup: $e');
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

    if (confirmed == true && backup.filePath != null) {
      try {
        await ref.read(backupOperationProvider.notifier).deleteBackupFile(backup.filePath!);
        if (mounted) {
          _refreshAllProviders();
          await DialogService.showSuccess(context, 'Backup deleted');
        }
      } catch (e) {
        if (mounted) {
          await DialogService.showError(context, 'Failed to delete: $e');
        }
      }
    }
  }

  void _refreshAllProviders() {
    // Invalidate Riverpod backup-related providers
    ref.invalidate(backupHistoryProvider);
    ref.invalidate(recentBackupsProvider);
    ref.invalidate(backupScheduleProvider);

    // Refresh Provider-based providers for deck/flashcard/analytics
    if (mounted) {
      context.read<DatabaseProvider>().refreshDecks();
      context.read<DatabaseProvider>().refreshAnalytics();
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
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
                color: _getStatusColor(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getStatusIcon(),
                color: _getStatusColor(context),
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

  Color _getStatusColor(BuildContext context) {
    switch (backup.status) {
      case BackupStatus.completed:
        return Theme.of(context).colorScheme.primary;
      case BackupStatus.failed:
        return Theme.of(context).colorScheme.error;
      case BackupStatus.creating:
      case BackupStatus.restoring:
        return Theme.of(context).colorScheme.tertiary;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
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
