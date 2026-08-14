import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/dialogs/backup_created_dialog.dart';

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
    final backupHistoryAsync = ref.watch(backupHistoryProvider);
    final settingsAsync = ref.watch(backupSettingsProvider);
    final statsAsync = ref.watch(backupStatisticsProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Backup & Restore',
      ),
      body: RefreshIndicator(
        onRefresh: _handlePullToRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Warning banner when the configured folder is no longer reachable.
            _buildFolderWarningBanner(settingsAsync),
            _buildBackupStatus(statsAsync, backupHistoryAsync),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildImportSection(),
            const SizedBox(height: 24),
            _buildAutomaticBackupSection(backupScheduleAsync),
            const SizedBox(height: 24),
            _buildRecentBackups(recentBackupsAsync),
            const SizedBox(height: 24),
            _buildCurrentBackupFolder(settingsAsync),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Warning banner (Phase 4 / Phase 9)
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildFolderWarningBanner(AsyncValue<BackupFolderInfo> settingsAsync) {
    return settingsAsync.when(
      data: (info) {
        if (info.exists) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          info.readError != null
                              ? 'Unable to read this folder.'
                              : 'Selected folder is no longer available.',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.folder, size: 18),
                          label: const Text('Choose Folder'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _handleChangeFolder,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.smartphone, size: 18),
                          label: const Text('Use Default'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _handleUseDefaultFolder,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Backup status (Phase 7 — dynamic statistics)
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildBackupStatus(
    AsyncValue<BackupStatistics> statsAsync,
    AsyncValue<List<BackupMetadata>> historyAsync,
  ) {
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
          statsAsync.when(
            data: (stats) {
              return Column(
                children: [
                  _buildStatusRow(
                    'Total Backups',
                    '${stats.totalBackups}',
                    Icons.backup_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    'Last Backup',
                    stats.lastBackupDate != null
                        ? _formatDateTime(stats.lastBackupDate!)
                        : 'Never',
                    Icons.schedule,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    'Data Protected',
                    _formatDataProtected(stats.dataProtected),
                    Icons.shield_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    'Total Backup Size',
                    stats.totalBackupSizeDisplay,
                    Icons.save_outlined,
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

  String _formatDataProtected(DataProtectedSummary summary) {
    final parts = <String>[
      '${summary.deckCount} decks',
      '${summary.flashcardCount} cards',
      if (summary.bookmarkCount > 0) '${summary.bookmarkCount} bookmarks',
      if (summary.analyticsCount > 0) '${summary.analyticsCount} analytics',
    ];
    return parts.join(', ');
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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Quick actions
  // ─────────────────────────────────────────────────────────────────────

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
            fullWidth: true,
            onPressed: _isCreatingBackup ? null : _handleCreateBackup,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Current backup folder (Phase 2 — real path display, Phase 6 — open UX)
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildCurrentBackupFolder(AsyncValue<BackupFolderInfo> settingsAsync) {
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
                'Current Backup Folder',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          settingsAsync.when(
            data: (info) => _buildFolderInfoDisplay(info),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => _buildPathDisplay(
              'Unable to read folder information',
              isCustom: false,
              showCopy: false,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Change Folder'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _handleChangeFolder,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('Open Folder'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _handleOpenFolder,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFolderInfoDisplay(BackupFolderInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Storage type badge.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: info.isUsingDefaultFolder
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            info.storageTypeLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: info.isUsingDefaultFolder
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 12),
        // Folder name (primary).
        Text(
          info.folderName,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        // Full path (secondary, soft wrapping) + copy icon.
        _buildPathDisplay(info.folderPath, isCustom: !info.isUsingDefaultFolder, showCopy: true),
        if (info.backupCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${info.backupCount} backup${info.backupCount == 1 ? '' : 's'} • ${info.totalSizeDisplay}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildPathDisplay(String path, {required bool isCustom, bool showCopy = true}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCustom ? Icons.create_new_folder : Icons.smartphone,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              path,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
              softWrap: true,
            ),
          ),
          if (showCopy)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy path',
              visualDensity: VisualDensity.compact,
              onPressed: () => _copyToClipboard(path),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Automatic backup
  // ─────────────────────────────────────────────────────────────────────

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
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
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

  // ─────────────────────────────────────────────────────────────────────
  //  Recent backups (Phase 5 — refresh + empty state)
  // ─────────────────────────────────────────────────────────────────────

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

              // Newest first (the service already sorts, but be defensive).
              final sorted = [...backups]
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              return Column(
                children: sorted.take(3).map((backup) {
                  return _BackupListItem(
                    backup: backup,
                    onTap: () => _showBackupDetails(backup),
                    onRestore: () => _handleRestore(backup),
                    onShare: () => _shareBackup(backup.filePath ?? ''),
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
            'Select a .db backup file from any location on your device.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Select Backup File',
            icon: Icons.file_open,
            isSecondary: true,
            fullWidth: true,
            onPressed: _handleImportBackup,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Handlers
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _handlePullToRefresh() async {
    ref.invalidate(backupSettingsProvider);
    ref.invalidate(backupStatisticsProvider);
    ref.invalidate(backupHistoryProvider);
    ref.invalidate(recentBackupsProvider);
    ref.invalidate(backupFilesProvider);
    ref.invalidate(backupScheduleProvider);
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
      // Show the modern Material 3 "Backup Created" bottom-sheet dialog.
      final folderName = await _resolveBackupFolderName();
      if (!mounted) return;
      await BackupCreatedDialog.show(
        context,
        fileName: result.fileName,
        savedTo: folderName,
        fileSizeDisplay: result.fileSizeDisplay,
        onShare: () {
          Navigator.of(context).pop();
          _shareBackup(result.filePath);
        },
        onOpenFolder: () {
          Navigator.of(context).pop();
          _handleOpenFolder();
        },
      );
    } else if (mounted) {
      await DialogService.showError(
        context,
        'Unable to save backup to the selected folder. Please check available storage.',
        title: 'Backup Failed',
      );
    }
  }

  Future<String> _resolveBackupFolderName() async {
    try {
      final info = await ref.read(backupSettingsProvider.future);
      return info.folderName;
    } catch (_) {
      return 'QuizSnap Backups';
    }
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
      // Note: FileType.custom with ['db'] is rejected by file_picker on
      // Android because .db has no MIME mapping. Use FileType.any and rely on
      // our SQLite header validation to reject non-database files.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select .db Backup File',
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

        // Validate SQLite header before proceeding.
        final isValid = await ref
            .read(backupOperationProvider.notifier)
            .validateSqliteFile(filePath);
        if (!isValid && mounted) {
          await DialogService.showError(
            context,
            'The selected file is not a valid QuizSnap .db backup. Please select a .db file created by QuizSnap.',
            title: 'Invalid Backup File',
          );
          return;
        }

        // Go straight to the restore confirmation flow for .db files.
        if (mounted) {
          await _confirmAndRestoreDbFile(filePath);
        }
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Failed to select file: $e');
      }
    }
  }

  Future<void> _confirmAndRestoreDbFile(String filePath) async {
    final fileName = filePath.split(Platform.pathSeparator).last;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restore from "$fileName"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.tertiary),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning,
                      color: Theme.of(context).colorScheme.tertiary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This will replace your current database with the backup. This action cannot be undone.',
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

    // Show a progress dialog while restoring.
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _RestoringProgressDialog(),
    );

    final newDb = await ref
        .read(backupOperationProvider.notifier)
        .restoreFromDbFile(filePath);

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss progress
    }

    if (newDb != null && mounted) {
      // Adopt the new database on the Provider-package side too so all
      // deck/flashcard/analytics screens refresh immediately.
      context.read<DatabaseProvider>().reopenDatabase(newDatabase: newDb);
      context.read<DatabaseProvider>().refreshDecks();
      context.read<DatabaseProvider>().refreshAnalytics();

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

  Future<void> _handleChangeFolder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangeBackupFolderScreen(),
      ),
    );

    // The ChangeBackupFolderScreen already shows its own success dialog on
    // save and invalidates the folder providers.  Do NOT show a second
    // success dialog here — that was the root cause of the duplicate dialog.
    // Provider invalidation refreshes the UI automatically on return.
  }

  Future<void> _handleUseDefaultFolder() async {
    final ok = await ref.read(backupOperationProvider.notifier).clearCustomBackupFolder();
    if (ok && mounted) {
      await DialogService.showSuccess(context, 'Reset to default backup location');
    } else if (mounted) {
      await DialogService.showError(context, 'Could not reset to the default folder.');
    }
  }

  Future<void> _handleOpenFolder() async {
    final backupService = ref.read(backupServiceProvider);

    // Resolve the active folder from the dynamic settings provider so we open
    // the real, currently-selected folder.
    BackupFolderInfo? info;
    try {
      info = await ref.read(backupSettingsProvider.future);
    } catch (_) {
      info = null;
    }

    final treeUri = info != null && info.folderPath.startsWith('content://')
        ? info.folderPath
        : await ref.read(customBackupTreeUriProvider.future);

    // Custom SAF folder: open the persisted tree URI.
    if (treeUri != null) {
      try {
        final success = await ref
            .read(backupOperationProvider.notifier)
            .openBackupFolder(treeUri);
        if (!success && mounted) {
          await _showOpenFolderFallbackDialog(info?.folderName, info?.folderPath ?? treeUri);
        }
      } catch (_) {
        if (mounted) {
          await _showOpenFolderFallbackDialog(info?.folderName, info?.folderPath ?? treeUri);
        }
      }
      return;
    }

    // Default app-specific folder: open via FileProvider content URI.
    final customPath = await ref.read(customBackupPathProvider.future);
    final directory = (customPath != null)
        ? Directory(customPath)
        : (info != null ? Directory(info.folderPath) : await backupService.getDefaultBackupDirectory());

    try {
      final success = await ref
          .read(backupOperationProvider.notifier)
          .openBackupFolder(directory.path);
      if (!success && mounted) {
        await _showOpenFolderFallbackDialog(info?.folderName, directory.path);
      }
    } catch (e) {
      if (mounted) {
        await _showOpenFolderFallbackDialog(info?.folderName, directory.path);
      }
    }
  }

  /// Friendly fallback dialog (Phase 6) showing the folder name, full path,
  /// and a Copy Path action.
  Future<void> _showOpenFolderFallbackDialog(String? folderName, String fullPath) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.folder_open, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Backup Location')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Platform.isAndroid
                  ? 'No compatible file manager was found. Your backup is saved inside QuizSnap. Use Share Backup to save a copy to Downloads, Google Drive, or another location.'
                  : 'Your backup is saved in the app\'s Documents folder. You can access it through the Files app or by sharing it.',
            ),
            const SizedBox(height: 16),
            if (folderName != null) ...[
              Text(
                'Folder',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              Text(folderName, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
            ],
            Text(
              'Path',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                fullPath,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                softWrap: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Path'),
            onPressed: () {
              Navigator.pop(context);
              _copyToClipboard(fullPath);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Path copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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

    // .db backups go through the direct restore flow.
    if (backup.filePath!.toLowerCase().endsWith('.db')) {
      await _confirmAndRestoreDbFile(backup.filePath!);
      return;
    }

    // Legacy .quizsnap / .json backups use the import preview screen.
    try {
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
    ref.invalidate(backupFilesProvider);
    ref.invalidate(backupSettingsProvider);
    ref.invalidate(backupStatisticsProvider);

    // Refresh Provider-based providers for deck/flashcard/analytics/settings.
    // notifyListeners() rebuilds every screen listening to DatabaseProvider.
    if (mounted) {
      final dbProvider = context.read<DatabaseProvider>();
      dbProvider.refreshDecks();
      dbProvider.refreshAnalytics();
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
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _BackupListItem({
    required this.backup,
    required this.onTap,
    required this.onRestore,
    required this.onShare,
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
              icon: const Icon(Icons.share),
              color: Theme.of(context).colorScheme.primary,
              onPressed: onShare,
              tooltip: 'Share',
            ),
            IconButton(
              icon: const Icon(Icons.restore),
              color: AppTheme.emerald600,
              onPressed: onRestore,
              tooltip: 'Restore',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Theme.of(context).colorScheme.error,
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

class _RestoringProgressDialog extends StatelessWidget {
  const _RestoringProgressDialog();

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
