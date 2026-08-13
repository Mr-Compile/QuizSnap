import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers/database_provider.dart';
import '../../core/providers/notification_service.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/back_button_handler.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';

/// Manual flashcard creation screen.
///
/// Supports deck, question, answer, tags, and a question-type classifier.
/// Question type is persisted by adding it as a tag on the card so the
/// existing Drift schema does not need a migration.
class CreateFlashcardScreen extends StatefulWidget {
  final int deckId;

  const CreateFlashcardScreen({
    super.key,
    required this.deckId,
  });

  @override
  State<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends State<CreateFlashcardScreen>
    with BackButtonHandlerMixin {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _tagsController = TextEditingController();
  final List<String> _selectedTags = [];
  String _questionType = 'basic';
  bool _isLoading = false;

  final Map<String, String> _questionTypeLabels = const {
    'basic': 'Basic flashcard',
    'multiple_choice': 'Multiple choice',
    'true_false': 'True / False',
    'identification': 'Identification',
  };

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
        resizeToAvoidBottomInset: true,
        appBar: const CustomAppBar(
          title: 'Create Flashcard',
        ),
        body: SingleChildScrollView(
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
                _buildDeckHeader(),
                const SizedBox(height: AppTheme.spacingLg),

                // Question type
                DropdownButtonFormField<String>(
                  key: ValueKey(_questionType),
                  initialValue: _questionType,
                  decoration: const InputDecoration(
                    labelText: 'Question type',
                    border: OutlineInputBorder(),
                  ),
                  items: _questionTypeLabels.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _questionType = value);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingLg),

                TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    hintText: 'Enter the question',
                    border: OutlineInputBorder(),
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
                    border: OutlineInputBorder(),
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

                TextFormField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: 'Tags',
                    hintText: 'Enter tags separated by commas',
                    border: const OutlineInputBorder(),
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
                      _selectedTags.clear();
                      _selectedTags.addAll(value
                          .split(',')
                          .map((t) => t.trim())
                          .where((t) => t.isNotEmpty));
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
                  text: 'Create Flashcard',
                  onPressed: _isLoading ? null : _createFlashcard,
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

  Widget _buildDeckHeader() {
    return FutureBuilder<Deck?>(
      future: _getDeck(),
      builder: (context, snapshot) {
        final deck = snapshot.data;
        final name = deck?.name ?? 'Selected deck';

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
                      name,
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
      },
    );
  }

  Future<Deck?> _getDeck() async {
    final db = context.read<DatabaseProvider>();
    try {
      return await db.deckRepository.getDeckById(widget.deckId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _createFlashcard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final db = context.read<DatabaseProvider>();
    try {
      final flashcards =
          await db.flashcardRepository.getFlashcardsByDeck(widget.deckId);
      final maxOrder = flashcards.isEmpty
          ? 0
          : flashcards.map((f) => f.order).reduce((a, b) => a > b ? a : b);

      final flashcardId =
          await db.flashcardRepository.createFlashcard(
        FlashcardsCompanion(
          question: drift.Value(_questionController.text.trim()),
          answer: drift.Value(_answerController.text.trim()),
          deckId: drift.Value(widget.deckId),
          order: drift.Value(maxOrder + 1),
        ),
      );

      // Persist tags + question type.
      final allTags = <String>[
        ..._selectedTags,
        'type:${_questionTypeLabels[_questionType]}',
      ];

      for (final tagName in allTags) {
        final existing = await db.tagRepository.getAllTags();
        Tag? tag;
        try {
          tag = existing.firstWhere((t) => t.name == tagName);
        } catch (_) {
          tag = null;
        }

        if (tag == null) {
          final tagId = await db.tagRepository.createTag(TagsCompanion(
            name: drift.Value(tagName),
            color: drift.Value('#4CAF50'),
          ));
          tag = Tag(
            id: tagId,
            name: tagName,
            color: '#4CAF50',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }

        await db.tagRepository.addTagToFlashcard(flashcardId, tag.id);
      }

      await db.deckRepository.updateDeckCardCount(widget.deckId);

      if (mounted) {
        context.read<NotificationService>().showSuccess('Flashcard created successfully');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        context.read<NotificationService>().showErrorTop('Error creating flashcard: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
