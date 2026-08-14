import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers/database_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/back_button_handler.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/flashcard_question_form.dart';

/// Edit flashcard screen with a dynamic, type-aware form mirroring the
/// create screen.  Loads the existing card, prefills all fields, and
/// preserves data when switching types until save.
class EditFlashcardScreen extends StatefulWidget {
  final int flashcardId;

  const EditFlashcardScreen({
    super.key,
    required this.flashcardId,
  });

  @override
  State<EditFlashcardScreen> createState() => _EditFlashcardScreenState();
}

class _EditFlashcardScreenState extends State<EditFlashcardScreen>
    with BackButtonHandlerMixin {
  bool _isLoading = true;
  bool _isSaving = false;
  Flashcard? _flashcard;
  final GlobalKey<FlashcardQuestionFormState> _formKey = GlobalKey();

  @override
  bool get hasUnsavedChanges =>
      _formKey.currentState?.hasUnsavedChanges ?? false;

  @override
  void initState() {
    super.initState();
    _loadFlashcardData();
  }

  Future<void> _loadFlashcardData() async {
    final dbProvider = context.read<DatabaseProvider>();
    try {
      final flashcard =
          await dbProvider.flashcardRepository.getFlashcardById(widget.flashcardId);
      if (mounted) {
        setState(() {
          _flashcard = flashcard;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        DialogService.showError(context, 'Error loading flashcard: $e');
        if (mounted) Navigator.of(context).pop();
      }
    }
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
        resizeToAvoidBottomInset: true,
        appBar: const CustomAppBar(
          title: 'Edit Flashcard',
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppTheme.spacingLg,
            right: AppTheme.spacingLg,
            top: AppTheme.spacingLg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingLg,
          ),
          child: FlashcardQuestionForm(
            key: _formKey,
            initialFlashcard: _flashcard,
            submitLabel: 'Save Changes',
            isSaving: _isSaving,
            onSubmit: _updateFlashcard,
          ),
        ),
      ),
    );
  }

  Future<void> _updateFlashcard(FlashcardFormData data) async {
    setState(() => _isSaving = true);

    final dbProvider = context.read<DatabaseProvider>();

    try {
      final flashcard =
          await dbProvider.flashcardRepository.getFlashcardById(widget.flashcardId);

      await dbProvider.flashcardRepository.updateFlashcard(
        flashcard.copyWith(
          question: data.question,
          answer: data.answer,
          questionType: data.questionType,
          optionA: drift.Value(data.optionA),
          optionB: drift.Value(data.optionB),
          optionC: drift.Value(data.optionC),
          optionD: drift.Value(data.optionD),
          correctOption: drift.Value(data.correctOption),
          enumerationItems: drift.Value(data.enumerationItemsJson),
          explanation: drift.Value(data.explanation),
        ),
      );

      dbProvider.refreshAll();

      if (mounted) {
        await DialogService.showSuccess(
          context,
          'Flashcard updated successfully',
        );
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        DialogService.showError(context, 'Error updating flashcard: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
