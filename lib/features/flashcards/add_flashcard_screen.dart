import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers/database_provider.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/back_button_handler.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/success_snackbar.dart';

class AddFlashcardScreen extends StatefulWidget {
  final int deckId;

  const AddFlashcardScreen({
    super.key,
    required this.deckId,
  });

  @override
  State<AddFlashcardScreen> createState() => _AddFlashcardScreenState();
}

class _AddFlashcardScreenState extends State<AddFlashcardScreen> with BackButtonHandlerMixin {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isLoading = false;
  List<String> _selectedTags = [];

  @override
  bool get hasUnsavedChanges {
    return _questionController.text.trim().isNotEmpty || 
           _answerController.text.trim().isNotEmpty ||
           _tagsController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildWithBackButtonHandler(
      Scaffold(
        appBar: const CustomAppBar(
          title: 'Add Flashcard',
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Deck selector (if needed for standalone creation)
                _buildDeckSelector(),
                const SizedBox(height: AppTheme.spacingLg),
                
                TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    hintText: 'Enter the question',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a question';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingLg),
                TextFormField(
                  controller: _answerController,
                  decoration: const InputDecoration(
                    labelText: 'Answer',
                    hintText: 'Enter the answer',
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an answer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingLg),
                
                // Tags field
                TextFormField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: 'Tags',
                    hintText: 'Enter tags separated by commas',
                    suffixIcon: _selectedTags.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _selectedTags.clear();
                                _tagsController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedTags = value
                          .split(',')
                          .map((tag) => tag.trim())
                          .where((tag) => tag.isNotEmpty)
                          .toList();
                    });
                  },
                ),
                
                if (_selectedTags.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedTags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () {
                          setState(() {
                            _selectedTags.remove(tag);
                            _tagsController.text = _selectedTags.join(', ');
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                
                const SizedBox(height: AppTheme.spacingXl),
                CustomButton(
                  text: 'Add Flashcard',
                  onPressed: _isLoading ? null : _addFlashcard,
                  fullWidth: true,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeckSelector() {
    // If deckId is provided, show deck info instead of selector
    return FutureBuilder<Deck>(
      future: context.read<DatabaseProvider>().deckRepository.getDeckById(widget.deckId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final deck = snapshot.data!;
          return Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.style,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adding to deck',
                        style: AppTheme.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        deck.name,
                        style: AppTheme.labelLarge.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _addFlashcard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final dbProvider = context.read<DatabaseProvider>();
    
    try {
      // Get the current max order for this deck
      final flashcards = await dbProvider.flashcardRepository.getFlashcardsByDeck(widget.deckId);
      final maxOrder = flashcards.isEmpty ? 0 : flashcards.map((f) => f.order).reduce((a, b) => a > b ? a : b);
      
      final flashcardId = await dbProvider.flashcardRepository.createFlashcard(
        FlashcardsCompanion(
          question: drift.Value(_questionController.text.trim()),
          answer: drift.Value(_answerController.text.trim()),
          deckId: drift.Value(widget.deckId),
          order: drift.Value(maxOrder + 1),
        ),
      );

      // Handle tags
      if (_selectedTags.isNotEmpty) {
        for (final tagName in _selectedTags) {
          // Get or create tag
          final existingTags = await dbProvider.tagRepository.getAllTags();
          Tag? tag;
          try {
            tag = existingTags.firstWhere((t) => t.name == tagName);
          } catch (e) {
            tag = null;
          }
          
          if (tag == null) {
            // Create new tag
            final tagId = await dbProvider.database.createTag(TagsCompanion(
              name: drift.Value(tagName),
              color: drift.Value('#4CAF50'),
            ));
            tag = Tag(id: tagId, name: tagName, color: '#4CAF50', createdAt: DateTime.now(), updatedAt: DateTime.now());
          }
          
          // Associate tag with flashcard
          await dbProvider.database.addTagToFlashcard(flashcardId, tag.id);
        }
      }

      // Update deck card count
      await dbProvider.deckRepository.updateDeckCardCount(widget.deckId);

      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: 'Flashcard added successfully',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding flashcard: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
