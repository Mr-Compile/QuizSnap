import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/back_button_handler.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../core/services/dialog_service.dart';

class EditDeckScreen extends StatefulWidget {
  final int deckId;

  const EditDeckScreen({
    super.key,
    required this.deckId,
  });

  @override
  State<EditDeckScreen> createState() => _EditDeckScreenState();
}

class _EditDeckScreenState extends State<EditDeckScreen> with BackButtonHandlerMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int? _selectedFolderId;
  String _selectedColor = '#4CAF50';
  bool _isLoading = true;
  bool _isSaving = false;

  // Store initial values for unsaved changes detection
  String _initialName = '';
  String _initialDescription = '';
  int? _initialFolderId;
  String _initialColor = '';

  @override
  bool get hasUnsavedChanges {
    return _nameController.text.trim() != _initialName ||
           _descriptionController.text.trim() != _initialDescription ||
           _selectedFolderId != _initialFolderId ||
           _selectedColor != _initialColor;
  }

  final List<String> _colors = const [
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#FF9800', // Orange
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#F44336', // Red
    '#00BCD4', // Cyan
    '#FFC107', // Amber
  ];

  @override
  void initState() {
    super.initState();
    _loadDeckData();
  }

  Future<void> _loadDeckData() async {
    final dbProvider = context.read<DatabaseProvider>();
    final deck = await dbProvider.deckRepository.getDeckById(widget.deckId);
    
    if (mounted) {
      setState(() {
        _nameController.text = deck.name;
        _descriptionController.text = deck.description ?? '';
        _selectedFolderId = deck.folderId;
        _selectedColor = deck.color;
        _isLoading = false;
        
        // Store initial values for unsaved changes detection
        _initialName = deck.name;
        _initialDescription = deck.description ?? '';
        _initialFolderId = deck.folderId;
        _initialColor = deck.color;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Edit Deck',
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return buildWithBackButtonHandler(
      Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: const CustomAppBar(
          title: 'Edit Deck',
        ),
        body: Consumer<DatabaseProvider>(
          builder: (context, dbProvider, child) {
            return FutureBuilder(
              future: dbProvider.folderRepository.getAllFolders(),
              builder: (context, snapshot) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: AppTheme.spacingLg,
                    right: AppTheme.spacingLg,
                    top: AppTheme.spacingLg,
                    bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingLg,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            hintText: 'Enter deck name',
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
                            hintText: 'Enter deck description',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        DropdownButtonFormField<int>(
                          // ignore: deprecated_member_use
                          value: _selectedFolderId,
                          decoration: const InputDecoration(
                            labelText: 'Folder (required)',
                            hintText: 'Select a folder',
                          ),
                          items: snapshot.hasData
                              ? snapshot.data!.map((folder) {
                                  return DropdownMenuItem<int>(
                                    value: folder.id,
                                    child: Text(folder.name),
                                  );
                                }).toList()
                              : null,
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a folder';
                            }
                            return null;
                          },
                          onChanged: (value) => setState(() => _selectedFolderId = value),
                        ),
                        if (snapshot.hasData && snapshot.data!.isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                            child: Text(
                              'No folders yet. Create a folder first to organize your decks.',
                              style: AppTheme.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.create_new_folder_outlined),
                            label: const Text('Create Folder'),
                            onPressed: () =>
                                GoRouter.of(context).push('/folders/create'),
                          ),
                        ],
                        const SizedBox(height: AppTheme.spacingLg),
                        Text(
                          'Color',
                          style: AppTheme.labelLarge,
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Wrap(
                          spacing: AppTheme.spacingSm,
                          runSpacing: AppTheme.spacingSm,
                          children: _colors.map((color) {
                            return Semantics(
                              button: true,
                              label: 'Select ${_selectedColor == color ? 'selected' : ''} color',
                              selected: _selectedColor == color,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedColor = color),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _selectedColor == color
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  child: _selectedColor == color
                                      ? Icon(
                                          Icons.check,
                                          color: Theme.of(context).colorScheme.onPrimary,
                                        )
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppTheme.spacingXl),
                        CustomButton(
                          text: 'Save Changes',
                          onPressed: _isSaving ? null : _updateDeck,
                          fullWidth: true,
                          isLoading: _isSaving,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _updateDeck() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Folder-first: a deck must always belong to a folder.
    if (_selectedFolderId == null) {
      await DialogService.showError(context, 'Please select a folder for this deck.');
      return;
    }

    setState(() => _isSaving = true);

    final dbProvider = context.read<DatabaseProvider>();

    try {
      final deck = await dbProvider.deckRepository.getDeckById(widget.deckId);

      await dbProvider.deckRepository.updateDeck(
        deck.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? const drift.Value(null)
              : drift.Value(_descriptionController.text.trim()),
          folderId: drift.Value(_selectedFolderId!),
          color: _selectedColor,
        ),
      );

      // Trigger dependent consumers (e.g. LibraryScreen) to rebuild.
      dbProvider.refreshAll();

      if (mounted) {
        await DialogService.showSuccess(context, 'Deck updated successfully');
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Error updating deck: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
