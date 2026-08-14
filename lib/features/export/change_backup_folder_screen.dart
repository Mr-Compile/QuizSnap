import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _selectedFullPath;
  DateTime? _selectedLastModified;
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
    final legacyPath = await ref.read(customBackupPathProvider.future);

    final path = treeUri ?? legacyPath;
    if (mounted) {
      setState(() {
        _selectedTreeUri = treeUri ?? legacyPath;
        _selectedFolderName = name ?? legacyPath?.split(Platform.pathSeparator).where((s) => s.isNotEmpty).last;
        _selectedFullPath = path;
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

  // ─────────────────────────────────────────────────────────────────────
  //  Current Folder Card (Phase 3)
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildCurrentFolderCard() {
    final isCustom = _selectedTreeUri != null;
    final folderName = isCustom
        ? (_selectedFolderName ?? 'Custom folder')
        : 'QuizSnap Backups';
    final fullPath = _selectedFullPath ??
        'Default app storage (QuizSnap/Backups)';

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
          // Storage type badge.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCustom
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isCustom ? 'Custom' : 'Default',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isCustom
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          // Folder name (primary).
          Row(
            children: [
              Icon(
                isCustom ? Icons.create_new_folder : Icons.smartphone,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  folderName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Full path underneath (secondary, soft wrapping) + copy icon.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    fullPath,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                    softWrap: true,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy path',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _copyToClipboard(fullPath),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Open Folder quick action.
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Open Folder'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _openCurrentFolder,
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
            fullWidth: true,
            onPressed: isDefault ? null : _useDefaultLocation,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Custom Folder Card (Phase 3)
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildCustomFolderCard() {
    final hasSelection = _selectedTreeUri != null && _hasChanges;
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
            fullWidth: true,
            onPressed: _selectCustomFolder,
          ),
          if (hasSelection) ...[
            const SizedBox(height: 16),
            // Read-only text field showing the selected folder name.
            TextField(
              controller: TextEditingController(text: _selectedFolderName ?? 'Custom folder'),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Selected Folder',
                prefixIcon: const Icon(Icons.folder),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                suffixIcon: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Secondary path text below.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Full path',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedFullPath ?? _selectedTreeUri ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                    softWrap: true,
                  ),
                  if (_selectedLastModified != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last modified: ${_formatDateTime(_selectedLastModified!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ],
              ),
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
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _isLoading || !_hasChanges ? null : _saveChanges,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
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
      _selectedFullPath = null;
      _selectedLastModified = null;
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

      DateTime? lastModified;
      try {
        // For filesystem paths we can stat the folder; SAF URIs cannot be
        // stat'd directly so we leave lastModified null.
        if (!directoryPath.startsWith('content://')) {
          final dir = Directory(directoryPath);
          if (await dir.exists()) {
            lastModified = (await dir.stat()).modified;
          }
        }
      } catch (_) {
        // Ignore stat errors; lastModified is optional.
      }

      if (name != null) {
        setState(() {
          _selectedTreeUri = directoryPath;
          _selectedFolderName = name;
          _selectedFullPath = directoryPath;
          _selectedLastModified = lastModified;
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
          _selectedFullPath = directoryPath;
          _selectedLastModified = lastModified;
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

  Future<void> _openCurrentFolder() async {
    final path = _selectedFullPath;
    if (path == null) {
      // Default folder: resolve via the service.
      try {
        final dir = await ref.read(backupServiceProvider).getDefaultBackupDirectory();
        await _tryOpenFolder(dir.path, _selectedFolderName);
      } catch (_) {
        if (mounted) {
          await DialogService.showInfo(context, 'Could not open the default backup folder.');
        }
      }
      return;
    }
    await _tryOpenFolder(path, _selectedFolderName);
  }

  Future<void> _tryOpenFolder(String path, String? name) async {
    try {
      final success = await ref
          .read(backupOperationProvider.notifier)
          .openBackupFolder(path);
      if (!success && mounted) {
        await _showOpenFallbackDialog(name, path);
      }
    } catch (_) {
      if (mounted) {
        await _showOpenFallbackDialog(name, path);
      }
    }
  }

  Future<void> _showOpenFallbackDialog(String? folderName, String fullPath) async {
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
                  ? 'No compatible file manager was found. Use Share Backup to save a copy to Downloads, Google Drive, or another location.'
                  : 'Your backup is saved in the app\'s Documents folder.',
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
