import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/success_snackbar.dart';

class RenameFolderDialog extends StatefulWidget {
  final int folderId;
  final String currentName;
  final String? currentDescription;

  const RenameFolderDialog({
    super.key,
    required this.folderId,
    required this.currentName,
    this.currentDescription,
  });

  @override
  State<RenameFolderDialog> createState() => _RenameFolderDialogState();
}

class _RenameFolderDialogState extends State<RenameFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _descriptionController = TextEditingController(text: widget.currentDescription ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Rename Folder',
        style: AppTheme.textSmall,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter folder name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                if (value.length > 100) {
                  return 'Name must be less than 100 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Enter folder description',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _renameFolder,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _renameFolder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dbProvider = context.read<DatabaseProvider>();
    
    try {
      final folder = await dbProvider.folderRepository.getFolderById(widget.folderId);
      
      await dbProvider.folderRepository.updateFolder(
        folder.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        ),
      );

      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: 'Folder updated successfully',
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating folder: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
