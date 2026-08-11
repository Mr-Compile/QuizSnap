import 'package:flutter/material.dart';
import '../../core/models/backup_enhanced.dart';

class RestoreOptionsDialog extends StatefulWidget {
  final BackupData backupData;

  const RestoreOptionsDialog({
    super.key,
    required this.backupData,
  });

  @override
  State<RestoreOptionsDialog> createState() => _RestoreOptionsDialogState();
}

class _RestoreOptionsDialogState extends State<RestoreOptionsDialog> {
  RestoreMode _selectedMode = RestoreMode.merge;
  bool _createSafetyBackup = true;
  bool _includeExtractedDocuments = false;
  bool _validateBeforeRestore = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Restore Options'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose how to restore this backup:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRestoreModeSection(),
            const SizedBox(height: 16),
            _buildSafetyBackupSection(),
            const SizedBox(height: 16),
            _buildAdditionalOptionsSection(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _confirmRestore,
          child: const Text('Restore'),
        ),
      ],
    );
  }

  Widget _buildRestoreModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Restore Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        RadioListTile<RestoreMode>(
          title: const Text('Merge'),
          subtitle: const Text('Combine backup with existing data'),
          value: RestoreMode.merge,
          // ignore: deprecated_member_use
          groupValue: _selectedMode,
          // ignore: deprecated_member_use
          onChanged: (value) {
            setState(() {
              _selectedMode = value!;
            });
          },
        ),
        RadioListTile<RestoreMode>(
          title: const Text('Replace'),
          subtitle: const Text('Replace all existing data with backup'),
          value: RestoreMode.replace,
          // ignore: deprecated_member_use
          groupValue: _selectedMode,
          // ignore: deprecated_member_use
          onChanged: (value) {
            setState(() {
              _selectedMode = value!;
            });
          },
        ),
        if (_selectedMode == RestoreMode.replace)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Warning: This will delete all your current data before restoring.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSafetyBackupSection() {
    return SwitchListTile(
      title: const Text('Create Safety Backup'),
      subtitle: const Text('Automatically backup current data before restore'),
      value: _createSafetyBackup,
      onChanged: (value) {
        setState(() {
          _createSafetyBackup = value;
        });
      },
    );
  }

  Widget _buildAdditionalOptionsSection() {
    final hasExtractedDocs = widget.backupData.data.containsKey('extractedDocuments');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Options',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Validate Before Restore'),
          subtitle: const Text('Check backup integrity before restoring'),
          value: _validateBeforeRestore,
          onChanged: (value) {
            setState(() {
              _validateBeforeRestore = value;
            });
          },
        ),
        if (hasExtractedDocs)
          SwitchListTile(
            title: const Text('Include Extracted Documents'),
            subtitle: const Text('Restore cached document text (may increase size)'),
            value: _includeExtractedDocuments,
            onChanged: (value) {
              setState(() {
                _includeExtractedDocuments = value;
              });
            },
          ),
      ],
    );
  }

  void _confirmRestore() {
    final options = RestoreOptions(
      mode: _selectedMode,
      createSafetyBackup: _createSafetyBackup,
      includeExtractedDocuments: _includeExtractedDocuments,
      validateBeforeRestore: _validateBeforeRestore,
    );
    Navigator.pop(context, options);
  }
}
