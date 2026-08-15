import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/back_button_handler.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/flashcard_question_form.dart';

/// Manual flashcard creation screen launched from DeckDetailsScreen.
///
/// Uses the shared [FlashcardQuestionForm] so all three question types
/// (Identification, Enumeration, Multiple Choice) are supported with
/// type-specific fields — identical to [CreateFlashcardScreen].
class AddFlashcardScreen extends StatefulWidget {
  final int deckId;

  const AddFlashcardScreen({
    super.key,
    required this.deckId,
  });

  @override
  State<AddFlashcardScreen> createState() => _AddFlashcardScreenState();
}

class _AddFlashcardScreenState extends State<AddFlashcardScreen>
    with BackButtonHandlerMixin {
  bool _isLoading = false;
  final GlobalKey<FlashcardQuestionFormState> _formKey = GlobalKey();

  @override
  bool get hasUnsavedChanges =>
      _formKey.currentState?.hasUnsavedChanges ?? false;

  @override
  Widget build(BuildContext context) {
    return buildWithBackButtonHandler(
      Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: const CustomAppBar(
          title: 'Add Flashcard',
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppTheme.spacingLg,
            right: AppTheme.spacingLg,
            top: AppTheme.spacingLg,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDeckHeader(),
              const SizedBox(height: AppTheme.spacingLg),
              FlashcardQuestionForm(
                key: _formKey,
                submitLabel: 'Add Flashcard',
                isSaving: _isLoading,
                onSubmit: _addFlashcard,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeckHeader() {
    return FutureBuilder(
      future: _getDeck(),
      builder: (context, snapshot) {
        final name = snapshot.data?.name ?? 'Selected deck';

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

  Future<dynamic> _getDeck() async {
    final db = context.read<DatabaseProvider>();
    try {
      return await db.deckRepository.getDeckById(widget.deckId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _addFlashcard(FlashcardFormData data) async {
    setState(() => _isLoading = true);

    final db = context.read<DatabaseProvider>();
    try {
      final flashcards =
          await db.flashcardRepository.getFlashcardsByDeck(widget.deckId);
      final maxOrder = flashcards.isEmpty
          ? 0
          : flashcards.map((f) => f.order).reduce((a, b) => a > b ? a : b);

      await db.flashcardRepository.createFlashcard(
        data.toCompanion(
          deckId: widget.deckId,
          order: maxOrder + 1,
        ),
      );

      await db.deckRepository.updateDeckCardCount(widget.deckId);
      db.refreshAll();

      if (mounted) {
        // Await the success dialog before navigating so it doesn't get
        // dismissed immediately by the pop.
        await DialogService.showSuccess(
            context, 'Flashcard added successfully');
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        await DialogService.showError(context, 'Error adding flashcard: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
