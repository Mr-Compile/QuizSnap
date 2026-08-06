import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/success_snackbar.dart';

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({super.key});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedFolderId;
  String _selectedColor = '#4CAF50';

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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Create Deck',
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
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? const Value(null)
              : Value(_descriptionController.text.trim()),
          folderId: _selectedFolderId != null ? Value(_selectedFolderId!) : const Value(null),
          color: Value(_selectedColor),
        ),
      );

      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: 'Deck created successfully',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating deck: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
