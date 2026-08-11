import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/app_bar.dart';
import '../../core/providers/backup_provider.dart';

class ChangeBackupFolderScreen extends ConsumerStatefulWidget {
  const ChangeBackupFolderScreen({super.key});

  @override
  ConsumerState<ChangeBackupFolderScreen> createState() => _ChangeBackupFolderScreenState();
}

class _ChangeBackupFolderScreenState extends ConsumerState<ChangeBackupFolderScreen> {
  String? _selectedPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPath();
  }

  Future<void> _loadCurrentPath() async {
    final customPath = await ref.read(customBackupPathProvider.future);
    if (mounted) {
      setState(() {
        _selectedPath = customPath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Change Backup Folder',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCurrentFolderCard(),
          const SizedBox(height: 16),
          _buildDefaultFolderCard(),
          const SizedBox(height: 16),
          _buildCustomFolderCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
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
            child: Text(
              _selectedPath ?? 'Using default location',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultFolderCard() {
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
            'Use the app\'s default backup folder in internal storage.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Use Default',
            isSecondary: true,
            onPressed: _selectedPath == null ? null : _useDefaultLocation,
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
            'Choose a custom folder for storing backups. Useful for syncing with cloud storage.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Select Folder',
            icon: Icons.folder,
            onPressed: _selectCustomFolder,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: 'Save Changes',
          onPressed: _isLoading ? null : _saveChanges,
          isLoading: _isLoading,
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

  Future<void> _useDefaultLocation() async {
    setState(() {
      _selectedPath = null;
    });
  }

  Future<void> _selectCustomFolder() async {
    try {
      final directoryPath = await FilePicker.platform.getDirectoryPath();
      
      if (directoryPath != null && mounted) {
        setState(() {
          _selectedPath = directoryPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select folder: $e')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(backupOperationProvider.notifier).setCustomBackupPath(_selectedPath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedPath == null 
                ? 'Reset to default backup location' 
                : 'Custom backup location saved'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
