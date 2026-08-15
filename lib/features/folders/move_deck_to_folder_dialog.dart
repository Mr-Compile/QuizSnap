import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/dialog_service.dart';

class MoveDeckToFolderDialog extends StatefulWidget {
  final int deckId;
  final int? currentFolderId;

  const MoveDeckToFolderDialog({
    super.key,
    required this.deckId,
    this.currentFolderId,
  });

  @override
  State<MoveDeckToFolderDialog> createState() => _MoveDeckToFolderDialogState();
}

class _MoveDeckToFolderDialogState extends State<MoveDeckToFolderDialog> {
  late int? _selectedFolderId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedFolderId = widget.currentFolderId;
  }

  @override
  Widget build(BuildContext context) {
    final dbProvider = context.read<DatabaseProvider>();

    return AlertDialog(
      title: const Text('Move to Folder'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Folder>>(
          future: dbProvider.folderRepository.getAllFolders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Error loading folders: ${snapshot.error}');
            }

            final folders = snapshot.data ?? [];

            if (folders.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No folders available. Create a folder first.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return RadioGroup<int?>(
              groupValue: _selectedFolderId,
              onChanged: (value) {
                if (!_isSaving) {
                  setState(() => _selectedFolderId = value);
                }
              },
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...folders.map((folder) {
                    return RadioListTile<int?>(
                      title: Text(folder.name),
                      value: folder.id,
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _move(_selectedFolderId),
          child: const Text('Move'),
        ),
      ],
    );
  }

  Future<void> _move(int? folderId) async {
    // Folder-first: a deck must always belong to a folder.
    if (folderId == null) {
      await DialogService.showError(context, 'Please select a folder.');
      return;
    }

    if (folderId == _selectedFolderId) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);

    final dbProvider = context.read<DatabaseProvider>();
    try {
      await dbProvider.deckRepository.moveDeckToFolder(widget.deckId, folderId);
      // Trigger dependent consumers (LibraryScreen, FolderDetailsScreen) to rebuild.
      dbProvider.refreshAll();
      if (mounted) {
        await DialogService.showSuccess(context, 'Deck moved successfully');
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Error moving deck: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
