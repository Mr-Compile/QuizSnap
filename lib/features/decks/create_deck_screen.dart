import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift hide Column;
import '../../core/providers/database_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/back_button_handler.dart';
import '../../core/navigation/app_routes.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';

class CreateDeckScreen extends StatefulWidget {
  /// Optional pre-selected folder ID (e.g. when creating from inside a folder).
  final int? initialFolderId;

  const CreateDeckScreen({
    super.key,
    this.initialFolderId,
  });

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> with BackButtonHandlerMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late int? _selectedFolderId;
  String _selectedColor = '#4CAF50';
  bool _isLoading = false;

  late final String _initialName;
  late final String _initialDescription;
  late final int? _initialFolderId;
  late final String _initialColor;

  @override
  void initState() {
    super.initState();
    _selectedFolderId = widget.initialFolderId;
    _initialName = '';
    _initialDescription = '';
    _initialFolderId = widget.initialFolderId;
    _initialColor = '#4CAF50';
  }

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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildWithBackButtonHandler(
      Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: const CustomAppBar(
          title: 'Create Deck',
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
                          initialValue: _selectedFolderId,
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
                                GoRouter.of(context).push(AppRoutes.createFolder),
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
                          text: 'Create Deck',
                          onPressed: _isLoading ? null : _createDeck,
                          fullWidth: true,
                          isLoading: _isLoading,
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

  void _createDeck() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Folder-first: a deck must belong to a folder.
    if (_selectedFolderId == null) {
      await DialogService.showError(context, 'Please select a folder for this deck.');
      return;
    }

    setState(() => _isLoading = true);

    final dbProvider = context.read<DatabaseProvider>();

    try {
      final deckId = await dbProvider.deckRepository.createDeck(
        DecksCompanion(
          name: drift.Value(_nameController.text.trim()),
          description: _descriptionController.text.trim().isEmpty
              ? const drift.Value(null)
              : drift.Value(_descriptionController.text.trim()),
          folderId: drift.Value(_selectedFolderId!),
          color: drift.Value(_selectedColor),
        ),
      );

      // Trigger dependent consumers (e.g. LibraryScreen) to rebuild.
      dbProvider.refreshAll();

      if (mounted) {
        await DialogService.showSuccess(context, 'Deck created successfully');
      }
      if (mounted) {
        // Replace this create screen with the new deck's details screen so
        // the user lands on the deck they just created (back returns to the
        // Library rather than the create form).
        GoRouter.of(context).pushReplacement('${AppRoutes.decks}/$deckId');
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Error creating deck: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
