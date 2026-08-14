import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift show Value;
import '../../core/database/database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/question_type_helper.dart';
import 'custom_button.dart';

/// A reusable, dynamic flashcard authoring form that adapts its fields
/// based on the selected [QuestionTypeHelper] type.
///
/// Used by both the Create and Edit flashcard screens so validation and
/// field behaviour stay identical.
class FlashcardQuestionForm extends StatefulWidget {
  /// Initial values for editing.  When null the form starts empty
  /// (create mode).
  final Flashcard? initialFlashcard;

  final bool isSaving;
  final String submitLabel;
  final VoidCallback? onCancel;
  final void Function(FlashcardFormData data) onSubmit;

  const FlashcardQuestionForm({
    super.key,
    this.initialFlashcard,
    this.isSaving = false,
    required this.submitLabel,
    this.onCancel,
    required this.onSubmit,
  });

  @override
  State<FlashcardQuestionForm> createState() => FlashcardQuestionFormState();
}

/// The collected form data ready to be persisted.
class FlashcardFormData {
  final String questionType;
  final String question;
  final String answer;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final String? correctOption;
  final String? enumerationItemsJson;
  final String? explanation;

  FlashcardFormData({
    required this.questionType,
    required this.question,
    required this.answer,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    this.correctOption,
    this.enumerationItemsJson,
    this.explanation,
  });

  /// Builds the [FlashcardsCompanion] for a new insert.
  drift.Value<String> get questionTypeValue => drift.Value(questionType);

  FlashcardsCompanion toCompanion({required int deckId, required int order}) {
    return FlashcardsCompanion(
      question: drift.Value(question),
      answer: drift.Value(answer),
      deckId: drift.Value(deckId),
      order: drift.Value(order),
      questionType: drift.Value(questionType),
      optionA: drift.Value(optionA),
      optionB: drift.Value(optionB),
      optionC: drift.Value(optionC),
      optionD: drift.Value(optionD),
      correctOption: drift.Value(correctOption),
      enumerationItems: drift.Value(enumerationItemsJson),
      explanation: drift.Value(explanation),
    );
  }
}

class FlashcardQuestionFormState extends State<FlashcardQuestionForm> {
  final _formKey = GlobalKey<FormState>();
  late String _questionType;

  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  late final TextEditingController _explanationController;
  late final TextEditingController _optionAController;
  late final TextEditingController _optionBController;
  late final TextEditingController _optionCController;
  late final TextEditingController _optionDController;
  late String _correctOption;
  late List<String> _enumerationItems;

  @override
  void initState() {
    super.initState();
    final f = widget.initialFlashcard;
    _questionType = f?.questionType ?? QuestionTypeHelper.identification;
    _questionController = TextEditingController(text: f?.question ?? '');
    _answerController = TextEditingController(text: f?.answer ?? '');
    _explanationController = TextEditingController(text: f?.explanation ?? '');
    _optionAController = TextEditingController(text: f?.optionA ?? '');
    _optionBController = TextEditingController(text: f?.optionB ?? '');
    _optionCController = TextEditingController(text: f?.optionC ?? '');
    _optionDController = TextEditingController(text: f?.optionD ?? '');
    _correctOption = f?.correctOption ?? '';
    _enumerationItems = QuestionTypeHelper.decodeEnumerationItems(
      f?.enumerationItems,
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _explanationController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    super.dispose();
  }

  bool get hasUnsavedChanges {
    final f = widget.initialFlashcard;
    if (f == null) {
      return _questionController.text.trim().isNotEmpty ||
          _answerController.text.trim().isNotEmpty ||
          _explanationController.text.trim().isNotEmpty ||
          _optionAController.text.trim().isNotEmpty ||
          _optionBController.text.trim().isNotEmpty ||
          _optionCController.text.trim().isNotEmpty ||
          _optionDController.text.trim().isNotEmpty ||
          _enumerationItems.isNotEmpty;
    }
    return _questionController.text.trim() != f.question ||
        _answerController.text.trim() != f.answer ||
        _explanationController.text.trim() != (f.explanation ?? '') ||
        _optionAController.text.trim() != (f.optionA ?? '') ||
        _optionBController.text.trim() != (f.optionB ?? '') ||
        _optionCController.text.trim() != (f.optionC ?? '') ||
        _optionDController.text.trim() != (f.optionD ?? '') ||
        _correctOption != (f.correctOption ?? '') ||
        _questionType != f.questionType;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Trim empty enumeration items before saving.
    final trimmedItems = _enumerationItems
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String answer;
    String? enumJson;
    String? optA, optB, optC, optD, correctOpt;

    switch (_questionType) {
      case QuestionTypeHelper.multipleChoice:
        optA = _optionAController.text.trim();
        optB = _optionBController.text.trim();
        optC = _optionCController.text.trim();
        optD = _optionDController.text.trim();
        correctOpt = _correctOption;
        final opts = [optA, optB, optC, optD];
        final idx = QuestionTypeHelper.letterToIndex(correctOpt);
        answer = idx >= 0 ? opts[idx] : optA;
        break;
      case QuestionTypeHelper.enumeration:
        enumJson = QuestionTypeHelper.encodeEnumerationItems(trimmedItems);
        answer = trimmedItems.join(', ');
        break;
      case QuestionTypeHelper.identification:
      default:
        answer = _answerController.text.trim();
        break;
    }

    widget.onSubmit(FlashcardFormData(
      questionType: _questionType,
      question: _questionController.text.trim(),
      answer: answer,
      optionA: optA,
      optionB: optB,
      optionC: optC,
      optionD: optD,
      correctOption: correctOpt,
      enumerationItemsJson: enumJson,
      explanation: _explanationController.text.trim().isEmpty
          ? null
          : _explanationController.text.trim(),
    ));
  }

  Future<bool> _confirmDiscardIncompatibleFields(
    String oldType,
    String newType,
  ) async {
    final hasData = _answerController.text.trim().isNotEmpty ||
        _optionAController.text.trim().isNotEmpty ||
        _optionBController.text.trim().isNotEmpty ||
        _optionCController.text.trim().isNotEmpty ||
        _optionDController.text.trim().isNotEmpty ||
        _enumerationItems.isNotEmpty;
    if (!hasData) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Change question type?'),
            content: Text(
              'Switching from ${QuestionTypeHelper.label(oldType)} to '
              '${QuestionTypeHelper.label(newType)} will hide the current '
              'type-specific fields. Your data is preserved until you save, '
              'but you may need to re-enter it.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Switch'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTypeSelector(),
          const SizedBox(height: AppTheme.spacingLg),
          _buildQuestionField(),
          const SizedBox(height: AppTheme.spacingLg),
          ..._buildTypeSpecificFields(),
          const SizedBox(height: AppTheme.spacingLg),
          _buildExplanationField(),
          const SizedBox(height: AppTheme.spacingXl),
          Row(
            children: [
              if (widget.onCancel != null) ...[
                Expanded(
                  child: CustomButton(
                    text: 'Cancel',
                    onPressed: widget.onCancel,
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
              ],
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: widget.submitLabel,
                  onPressed: widget.isSaving ? null : _submit,
                  fullWidth: true,
                  isLoading: widget.isSaving,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Type selector (Material 3 segmented control) ───────────────────────

  Widget _buildTypeSelector() {
    final segments = <ButtonSegment<String>>[
      ButtonSegment(
        value: QuestionTypeHelper.identification,
        label: Text(
          QuestionTypeHelper.shortLabel(QuestionTypeHelper.identification),
        ),
        icon: const Icon(Icons.search, size: 18),
      ),
      ButtonSegment(
        value: QuestionTypeHelper.enumeration,
        label: Text(
          QuestionTypeHelper.shortLabel(QuestionTypeHelper.enumeration),
        ),
        icon: const Icon(Icons.list, size: 18),
      ),
      ButtonSegment(
        value: QuestionTypeHelper.multipleChoice,
        label: Text(
          QuestionTypeHelper.shortLabel(QuestionTypeHelper.multipleChoice),
        ),
        icon: const Icon(Icons.quiz, size: 18),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question Type', style: AppTheme.labelLarge),
        const SizedBox(height: AppTheme.spacingSm),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: segments,
            selected: {_questionType},
            onSelectionChanged: (selection) async {
              final newType = selection.first;
              if (newType == _questionType) return;
              final confirmed =
                  await _confirmDiscardIncompatibleFields(
                    _questionType,
                    newType,
                  );
              if (!confirmed || !mounted) return;
              setState(() => _questionType = newType);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionField() {
    return TextFormField(
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
    );
  }

  // ── Type-specific fields ───────────────────────────────────────────────

  List<Widget> _buildTypeSpecificFields() {
    switch (_questionType) {
      case QuestionTypeHelper.identification:
        return _buildIdentificationFields();
      case QuestionTypeHelper.enumeration:
        return _buildEnumerationFields();
      case QuestionTypeHelper.multipleChoice:
        return _buildMultipleChoiceFields();
      default:
        return _buildIdentificationFields();
    }
  }

  List<Widget> _buildIdentificationFields() {
    return [
      TextFormField(
        controller: _answerController,
        decoration: const InputDecoration(
          labelText: 'Answer',
          hintText: 'Enter the correct answer',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter an answer';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildEnumerationFields() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Items', style: AppTheme.labelLarge),
          TextButton.icon(
            onPressed: _addEnumerationItem,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
        ],
      ),
      if (_enumerationItems.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
          child: Text(
            'Add at least one item.',
            style: AppTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: _enumerationItems.length,
        onReorderItem: (oldIndex, newIndex) {
          setState(() {
            final item = _enumerationItems.removeAt(oldIndex);
            _enumerationItems.insert(newIndex, item);
          });
        },
        proxyDecorator: (child, index, animation) => Material(
          color: Colors.transparent,
          child: child,
        ),
        itemBuilder: (context, index) {
          return _buildEnumerationItemTile(index, _enumerationItems[index]);
        },
      ),
    ];
  }

  Widget _buildEnumerationItemTile(int index, String item) {
    return Dismissible(
      key: ValueKey('enum_${index}_$item'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeEnumerationItem(index),
      background: Container(
        alignment: Alignment.centerRight,
        color: Theme.of(context).colorScheme.error,
        child: const Padding(
          padding: EdgeInsets.only(right: AppTheme.spacingMd),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      child: Padding(
        key: ValueKey('enum_tile_$index'),
        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
                child: Icon(Icons.drag_indicator),
              ),
            ),
            Text('${index + 1}.', style: AppTheme.labelMedium),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(child: Text(item)),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => _removeEnumerationItem(index),
              tooltip: 'Remove item',
            ),
          ],
        ),
      ),
    );
  }

  void _addEnumerationItem() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Item ${_enumerationItems.length + 1}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Item',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final trimmed = value.trim();
            if (trimmed.isNotEmpty) {
              setState(() => _enumerationItems.add(trimmed));
            }
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) {
                setState(() => _enumerationItems.add(trimmed));
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _removeEnumerationItem(int index) {
    setState(() => _enumerationItems.removeAt(index));
  }

  List<Widget> _buildMultipleChoiceFields() {
    return [
      _buildOptionField('A', _optionAController),
      const SizedBox(height: AppTheme.spacingSm),
      _buildOptionField('B', _optionBController),
      const SizedBox(height: AppTheme.spacingSm),
      _buildOptionField('C', _optionCController),
      const SizedBox(height: AppTheme.spacingSm),
      _buildOptionField('D', _optionDController),
      const SizedBox(height: AppTheme.spacingMd),
      Text('Correct Answer', style: AppTheme.labelLarge),
      const SizedBox(height: AppTheme.spacingSm),
      _buildCorrectOptionSelector(),
    ];
  }

  Widget _buildOptionField(
    String letter,
    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Option $letter',
        hintText: 'Enter option $letter',
        border: const OutlineInputBorder(),
        prefix: Text('$letter.  '),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Option $letter is required';
        }
        return null;
      },
    );
  }

  Widget _buildCorrectOptionSelector() {
    return FormField<String>(
      initialValue: _correctOption,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select the correct answer';
        }
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppTheme.spacingSm,
              children: QuestionTypeHelper.optionLetters.map((letter) {
                final selected = _correctOption == letter;
                return ChoiceChip(
                  label: Text(letter),
                  selected: selected,
                  onSelected: (isSelected) {
                    if (isSelected) {
                      setState(() => _correctOption = letter);
                      field.didChange(letter);
                    }
                  },
                );
              }).toList(),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingXs),
                child: Text(
                  field.errorText ?? '',
                  style: AppTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildExplanationField() {
    return TextFormField(
      controller: _explanationController,
      decoration: const InputDecoration(
        labelText: 'Explanation (optional)',
        hintText: 'Shown after reveal / in exam review',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }
}
