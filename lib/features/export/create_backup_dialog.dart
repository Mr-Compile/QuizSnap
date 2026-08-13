import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/custom_button.dart';
import '../../core/providers/backup_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../core/theme/app_theme.dart';
import 'export_success_screen_backup.dart';

class CreateBackupDialog extends ConsumerStatefulWidget {
  const CreateBackupDialog({super.key});

  @override
  ConsumerState<CreateBackupDialog> createState() => _CreateBackupDialogState();
}

class _CreateBackupDialogState extends ConsumerState<CreateBackupDialog> {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
      ),
      elevation: 0,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? AppTheme.spacing8 : AppTheme.spacing6,
        vertical: AppTheme.spacing6,
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? AppTheme.spacing8 : AppTheme.spacing4,
        vertical: AppTheme.spacing8,
      ),
      title: Text(
        'Create Backup',
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: isTablet ? AppTheme.text2xl : AppTheme.textLg,
          fontWeight: AppTheme.fontSemiBold,
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 520 : double.infinity,
        ),
        child: Form(
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
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a backup name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing4),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add a description for this backup',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  'This backup will include all your decks, flashcards, folders, tags, and study data.',
                  style: TextStyle(
                    fontSize: AppTheme.textXs,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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
      final backupFile = await ref.read(backupOperationProvider.notifier).exportBackup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted && backupFile != null) {
        Navigator.pop(context);
        // Navigate to success screen with file manager options
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExportSuccessScreenBackup(backupFile: backupFile),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showFriendlyError(
          context,
          'Failed to create backup: $e',
          title: 'Backup Failed',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}