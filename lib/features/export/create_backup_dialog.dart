import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../core/models/backup.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/backup_service.dart';
import '../../core/repositories/deck_repository.dart';
import '../../core/repositories/flashcard_repository.dart';
import '../../core/repositories/folder_repository.dart';
import '../../core/repositories/tag_repository.dart';

class CreateBackupDialog extends StatefulWidget {
  const CreateBackupDialog({super.key});

  @override
  State<CreateBackupDialog> createState() => _CreateBackupDialogState();
}

class _CreateBackupDialogState extends State<CreateBackupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Backup_${DateTime.now().millisecondsSinceEpoch}';
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
      title: const Text('Create Backup'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Backup Name',
                  hintText: 'Enter a name for this backup',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a backup name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add a description for this backup',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'This backup will include all your decks, flashcards, folders, tags, and study data.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: 'Create Backup',
          isLoading: _isCreating,
          onPressed: _isCreating ? null : _handleCreateBackup,
        ),
      ],
    );
  }

  Future<void> _handleCreateBackup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final database = context.read<AppDatabase>();
      final backupService = BackupService(
        database,
        DeckRepository(database),
        FlashcardRepository(database),
        FolderRepository(database),
        TagRepository(database),
      );

      final backup = await backupService.createBackup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, backup);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create backup: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}