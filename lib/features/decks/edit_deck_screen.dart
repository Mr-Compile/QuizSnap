import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/back_button_handler.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/success_snackbar.dart';

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

  final List<String> _colors = [
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
        appBar: const CustomAppBar(
          title: 'Edit Deck',
        ),
        body: Consumer<DatabaseProvider>(
          builder: (context, dbProvider, child) {
            return FutureBuilder(
              future: dbProvider.folderRepository.getAllFolders(),
              builder: (context, snapshot) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
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
                          value: _selectedFolderId,
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
                            return GestureDetector(
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
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                      )
                                    : null,
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

    setState(() => _isSaving = true);

    final dbProvider = context.read<DatabaseProvider>();
    
    try {
      final deck = await dbProvider.deckRepository.getDeckById(widget.deckId);
      
      await dbProvider.deckRepository.updateDeck(
        deck.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          folderId: _selectedFolderId != null ? Value(_selectedFolderId!) : const Value(null),
          color: _selectedColor,
        ),
      );

      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: 'Deck updated successfully',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating deck: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
