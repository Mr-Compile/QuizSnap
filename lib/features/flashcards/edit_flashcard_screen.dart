import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/back_button_handler.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/success_snackbar.dart';

class EditFlashcardScreen extends StatefulWidget {
  final int flashcardId;

  const EditFlashcardScreen({
    super.key,
    required this.flashcardId,
  });

  @override
  State<EditFlashcardScreen> createState() => _EditFlashcardScreenState();
}

class _EditFlashcardScreenState extends State<EditFlashcardScreen> with BackButtonHandlerMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  bool _isFavorite = false;
  bool _isLoading = true;
  bool _isSaving = false;

  // Store initial values for unsaved changes detection
  String _initialQuestion = '';
  String _initialAnswer = '';
  bool _initialFavorite = false;

  @override
  bool get hasUnsavedChanges {
    return _questionController.text.trim() != _initialQuestion ||
           _answerController.text.trim() != _initialAnswer ||
           _isFavorite != _initialFavorite;
  }

  @override
  void initState() {
    super.initState();
    _loadFlashcardData();
  }

  Future<void> _loadFlashcardData() async {
    final dbProvider = context.read<DatabaseProvider>();
    final flashcard = await dbProvider.flashcardRepository.getFlashcardById(widget.flashcardId);
    
    if (mounted) {
      setState(() {
        _questionController.text = flashcard.question;
        _answerController.text = flashcard.answer;
        _isFavorite = flashcard.isFavorite;
        _isLoading = false;
        
        // Store initial values for unsaved changes detection
        _initialQuestion = flashcard.question;
        _initialAnswer = flashcard.answer;
        _initialFavorite = flashcard.isFavorite;
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Edit Flashcard',
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return buildWithBackButtonHandler(
      Scaffold(
        appBar: const CustomAppBar(
          title: 'Edit Flashcard',
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
                const SizedBox(height: AppTheme.spacingLg),
                SwitchListTile(
                  title: const Text('Favorite'),
                  subtitle: const Text('Mark this flashcard as a favorite'),
                  value: _isFavorite,
                  onChanged: (value) => setState(() => _isFavorite = value),
                ),
                const SizedBox(height: AppTheme.spacingXl),
                CustomButton(
                  text: 'Save Changes',
                  onPressed: _isSaving ? null : _updateFlashcard,
                  fullWidth: true,
                  isLoading: _isSaving,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateFlashcard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dbProvider = context.read<DatabaseProvider>();
    
    try {
      final flashcard = await dbProvider.flashcardRepository.getFlashcardById(widget.flashcardId);
      
      await dbProvider.flashcardRepository.updateFlashcard(
        flashcard.copyWith(
          question: _questionController.text.trim(),
          answer: _answerController.text.trim(),
          isFavorite: _isFavorite,
        ),
      );

      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: 'Flashcard updated successfully',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating flashcard: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
