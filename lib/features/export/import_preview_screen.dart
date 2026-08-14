import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/app_bar.dart';
import '../../core/models/backup_enhanced.dart';
import '../../core/providers/backup_provider.dart';
import '../../core/providers/database_provider.dart';
import 'restore_options_dialog.dart';
import '../../core/services/dialog_service.dart';

class ImportPreviewScreen extends ConsumerStatefulWidget {
  final String filePath;

  const ImportPreviewScreen({
    super.key,
    required this.filePath,
  });

  @override
  ConsumerState<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen> {
  BackupData? _backupData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBackupData();
  }

  Future<void> _loadBackupData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final backupData = await backupService.importBackup(widget.filePath);
      
      if (mounted) {
        setState(() {
          _backupData = backupData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Import Backup',
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showBackupInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _backupData != null
                  ? _buildPreviewView()
                  : const Center(child: Text('No backup data available')),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Backup',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Try Again',
              onPressed: _loadBackupData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewView() {
    final metadata = _backupData!.metadata;
    final data = _backupData!.data;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBackupInfoCard(metadata),
        const SizedBox(height: 16),
        _buildDataContentsCard(data),
        const SizedBox(height: 16),
        _buildIntegrityCard(),
        const SizedBox(height: 24),
        _buildRestoreActions(),
      ],
    );
  }

  Widget _buildBackupInfoCard(BackupMetadata metadata) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.backup,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata.typeDisplay,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Created', _formatDateTime(metadata.createdAt)),
          _buildInfoRow('Size', metadata.fileSizeDisplay),
          _buildInfoRow('Version', 'v${metadata.version}'),
          if (metadata.description != null) ...[
            const SizedBox(height: 8),
            Text(
              'Description',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              metadata.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataContentsCard(Map<String, dynamic> data) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backup Contents',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildContentRow('Folders', data['folders']?.length ?? 0, Icons.folder),
          _buildContentRow('Decks', data['decks']?.length ?? 0, Icons.layers),
          _buildContentRow('Flashcards', data['flashcards']?.length ?? 0, Icons.style),
          _buildContentRow('Tags', data['tags']?.length ?? 0, Icons.label),
          _buildContentRow('Study Sessions', data['studySessions']?.length ?? 0, Icons.history),
          _buildContentRow('Quiz Results', data['quizResults']?.length ?? 0, Icons.assignment),
          if (data.containsKey('aiUsage'))
            _buildContentRow('AI Usage Records', data['aiUsage']?.length ?? 0, Icons.psychology),
          if (data.containsKey('extractedDocuments'))
            _buildContentRow('Extracted Documents', data['extractedDocuments']?.length ?? 0, Icons.description),
        ],
      ),
    );
  }

  Widget _buildContentRow(String label, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrityCard() {
    final isValid = _backupData!.verifyChecksum();
    final hasChecksum = _backupData!.checksum != null;

    return CustomCard(
      child: Row(
        children: [
          Icon(
            isValid ? Icons.verified : Icons.warning,
            color: isValid ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.tertiary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasChecksum ? 'Integrity Check' : 'No Checksum',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  hasChecksum
                      ? (isValid ? 'Backup file is valid' : 'Backup file may be corrupted')
                      : 'This backup has no integrity verification',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  Widget _buildRestoreActions() {
    return Column(
      children: [
        CustomButton(
          text: 'Restore Backup',
          icon: Icons.restore,
          onPressed: _showRestoreOptions,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Cancel',
          isSecondary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  void _showRestoreOptions() async {
    final options = await showDialog<RestoreOptions>(
      context: context,
      builder: (context) => RestoreOptionsDialog(
        backupData: _backupData!,
      ),
    );

    if (options != null && mounted) {
      await _performRestore(options);
    }
  }

  Future<void> _performRestore(RestoreOptions options) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              options.mode == RestoreMode.replace
                  ? 'This will replace all your current data with the backup.'
                  : 'This will merge the backup with your current data.',
            ),
            const SizedBox(height: 16),
            if (options.createSafetyBackup)
              const Text('• A safety backup will be created automatically'),
            if (options.includeExtractedDocuments)
              const Text('• Extracted documents will be included'),
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
                  Icon(Icons.warning, color: Theme.of(context).colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _executeRestore(options);
    }
  }

  Future<void> _executeRestore(RestoreOptions options) async {
    setState(() => _isLoading = true);

    try {
      final result = await ref.read(backupOperationProvider.notifier).restoreBackup(
            _backupData!,
            options,
          );

      if (mounted) {
        if (result != null && result.success) {
          // Refresh all providers so UI updates immediately
          ref.invalidate(backupHistoryProvider);
          ref.invalidate(recentBackupsProvider);
          ref.invalidate(backupScheduleProvider);
          context.read<DatabaseProvider>().refreshDecks();
          context.read<DatabaseProvider>().refreshAnalytics();

          Navigator.pop(context, true);
          if (mounted) {
            await DialogService.showSuccess(
              context,
              'Your data has been restored successfully.',
              title: 'Restore Complete',
            );
          }
        } else {
          setState(() => _isLoading = false);
          await DialogService.showError(
            context,
            'The restore could not be completed. Please try again.',
            title: 'Restore Failed',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await DialogService.showError(context, 'Restore failed: $e');
      }
    }
  }

  void _showBackupInfo() {
    if (_backupData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('File Path', widget.filePath),
              _detailRow('Backup ID', _backupData!.metadata.id),
              _detailRow('Version', 'v${_backupData!.version}'),
              if (_backupData!.checksum != null)
                _detailRow('Checksum', '${_backupData!.checksum!.substring(0, 16)}...'),
              _detailRow('Created', _formatDateTime(_backupData!.metadata.createdAt)),
              if (_backupData!.metadata.completedAt != null)
                _detailRow('Completed', _formatDateTime(_backupData!.metadata.completedAt!)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
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
