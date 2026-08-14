import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/app_bar.dart';
import '../../core/providers/backup_provider.dart';
import '../../core/services/dialog_service.dart';

class ChangeBackupFolderScreen extends ConsumerStatefulWidget {
  const ChangeBackupFolderScreen({super.key});

  @override
  ConsumerState<ChangeBackupFolderScreen> createState() =>
      _ChangeBackupFolderScreenState();
}

class _ChangeBackupFolderScreenState
    extends ConsumerState<ChangeBackupFolderScreen> {
  String? _selectedTreeUri;
  String? _selectedFolderName;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentFolder();
  }

  Future<void> _loadCurrentFolder() async {
    final treeUri = await ref.read(customBackupTreeUriProvider.future);
    final name = await ref.read(customBackupFolderNameProvider.future);
    if (mounted) {
      setState(() {
        _selectedTreeUri = treeUri;
        _selectedFolderName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Change Backup Folder',
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCurrentFolderCard(),
                const SizedBox(height: 16),
                _buildDefaultFolderCard(),
                const SizedBox(height: 16),
                _buildCustomFolderCard(),
              ],
            ),
          ),
          _buildFooterActions(),
        ],
      ),
    );
  }

  Widget _buildCurrentFolderCard() {
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedTreeUri != null
                      ? Icons.create_new_folder
                      : Icons.smartphone,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedTreeUri != null
                        ? (_selectedFolderName ?? 'Custom folder')
                        : 'Default app storage (QuizSnap/Backups)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultFolderCard() {
    final isDefault = _selectedTreeUri == null && !_hasChanges;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smartphone,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Default Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Use the app\'s default backup folder in app-specific storage. No folder access permission is required.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Use Default',
            isSecondary: true,
            onPressed: isDefault ? null : _useDefaultLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFolderCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.create_new_folder,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Custom Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Choose a custom folder for storing backups. You\'ll be asked to grant access to the selected folder. Useful for syncing with cloud storage.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Select Folder',
            icon: Icons.folder,
            onPressed: _selectCustomFolder,
          ),
          if (_selectedTreeUri != null && _hasChanges) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFolderName ?? 'Custom folder',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Footer with Cancel (outlined) and Save Changes (primary) in one row.
  Widget _buildFooterActions() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _isLoading || !_hasChanges ? null : _saveChanges,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useDefaultLocation() async {
    setState(() {
      _selectedTreeUri = null;
      _selectedFolderName = null;
      _hasChanges = true;
    });
  }

  Future<void> _selectCustomFolder() async {
    try {
      // On Android, getDirectoryPath() returns a SAF tree URI string
      // (content://...). On desktop it returns a filesystem path.
      final directoryPath = await FilePicker.platform.getDirectoryPath();

      if (directoryPath == null || !mounted) return;

      // Persist the SAF tree URI (no-op on non-Android).
      final name = await ref
          .read(backupOperationProvider.notifier)
          .persistCustomTreeUri(directoryPath);

      if (name != null) {
        setState(() {
          _selectedTreeUri = directoryPath;
          _selectedFolderName = name;
          _hasChanges = true;
        });
      } else if (mounted) {
        // On desktop (no SAF), fall back to storing the filesystem path.
        await ref
            .read(backupOperationProvider.notifier)
            .setCustomBackupPath(directoryPath);
        setState(() {
          _selectedTreeUri = directoryPath;
          _selectedFolderName =
              directoryPath.split(Platform.pathSeparator).last;
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Failed to select folder: $e');
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedTreeUri == null) {
        // Revert to default.
        await ref.read(backupOperationProvider.notifier).clearCustomBackupFolder();
      }
      // The tree URI was already persisted during selection; nothing more to do.

      if (mounted) {
        setState(() => _isLoading = false);
        await DialogService.showSuccess(
          context,
          _selectedTreeUri == null
              ? 'Reset to default backup location'
              : 'Custom backup location saved',
        );
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await DialogService.showError(context, 'Failed to save changes: $e');
      }
    }
  }
}
