import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift hide Column;
import '../../core/providers/database_provider.dart';
import '../../core/providers/notification_service.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/back_button_handler.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/success_snackbar.dart';

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({super.key});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> with BackButtonHandlerMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedFolderId;
  String _selectedColor = '#4CAF50';
  
  final String _initialName = '';
  final String _initialDescription = '';
  final int? _initialFolderId = null;
  final String _initialColor = '#4CAF50';

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
                            labelText: 'Folder (optional)',
                            hintText: 'Select a folder',
                          ),
                          items: snapshot.hasData
                              ? [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('No Folder'),
                                  ),
                                  ...snapshot.data!.map((folder) {
                                    return DropdownMenuItem<int>(
                                      value: folder.id,
                                      child: Text(folder.name),
                                    );
                                  }),
                                ]
                              : null,
                          onChanged: (value) => setState(() => _selectedFolderId = value),
                        ),
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
                          onPressed: _createDeck,
                          fullWidth: true,
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

    final dbProvider = context.read<DatabaseProvider>();
    
    try {
      await dbProvider.deckRepository.createDeck(
        DecksCompanion(
          name: drift.Value(_nameController.text.trim()),
          description: _descriptionController.text.trim().isEmpty
              ? const drift.Value(null)
              : drift.Value(_descriptionController.text.trim()),
          folderId: _selectedFolderId != null ? drift.Value(_selectedFolderId!) : const drift.Value(null),
          color: drift.Value(_selectedColor),
        ),
      );

      // Trigger dependent consumers (e.g. DeckListScreen) to rebuild.
      dbProvider.refreshDecks();

      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: 'Deck created successfully',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.read<NotificationService>().showErrorTop('Error creating deck: $e');
      }
    }
  }
}
