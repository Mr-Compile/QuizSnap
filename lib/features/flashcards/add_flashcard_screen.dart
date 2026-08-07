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
  bool _isLoading = false;

  @override
  bool get hasUnsavedChanges {
    return _questionController.text.trim().isNotEmpty || 
           _answerController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
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
      
      await dbProvider.flashcardRepository.createFlashcard(
        FlashcardsCompanion(
          question: drift.Value(_questionController.text.trim()),
          answer: drift.Value(_answerController.text.trim()),
          deckId: drift.Value(widget.deckId),
          order: drift.Value(maxOrder + 1),
        ),
      );

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
