import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/exam_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/models/exam.dart';
import '../../core/services/dialog_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';
import 'pause_dialog.dart';
import 'submit_confirmation_dialog.dart';
import 'exam_result_screen.dart';

class ExamQuestionScreen extends StatefulWidget {
  final String examId;

  const ExamQuestionScreen({
    super.key,
    required this.examId,
  });

  @override
  State<ExamQuestionScreen> createState() => _ExamQuestionScreenState();
}

class _ExamQuestionScreenState extends State<ExamQuestionScreen> {
  Timer? _timer;
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, TextEditingController> _listInputControllers = {};

  TextEditingController _textControllerFor(String questionId, String initialText) {
    return _textControllers.putIfAbsent(
      questionId,
      () => TextEditingController(text: initialText),
    );
  }

  TextEditingController _listInputControllerFor(String questionId) {
    return _listInputControllers.putIfAbsent(
      questionId,
      () => TextEditingController(),
    );
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final examProvider = context.read<ExamProvider>();
      examProvider.updateTimer();

      if (examProvider.remainingTime <= Duration.zero) {
        _handleTimeExpired();
      }
    });
  }

  void _handleTimeExpired() {
    _timer?.cancel();
    _showTimeExpiredDialog();
  }

  void _showTimeExpiredDialog() {
    DialogService.showInfo(
      context,
      'Your exam time has expired. Your answers will be submitted automatically.',
      title: 'Time Expired',
      onAcknowledge: _submitExam,
    );
  }

  void _selectAnswer(int index) {
    final examProvider = context.read<ExamProvider>();
    examProvider.submitAnswer(index);
  }

  void _submitTextAnswer(String answer) {
    final examProvider = context.read<ExamProvider>();
    if (answer.trim().isNotEmpty) {
      examProvider.submitTextAnswer(answer.trim());
    }
  }

  void _syncTextAnswer() {
    final examProvider = context.read<ExamProvider>();
    final question = examProvider.currentQuestion;
    if (question == null) return;
    final controller = _textControllers[question.id];
    if (controller != null && controller.text.trim().isNotEmpty) {
      examProvider.submitTextAnswer(controller.text.trim());
    }
  }

  void _submitListAnswer(List<String> answers) {
    final examProvider = context.read<ExamProvider>();
    examProvider.submitListAnswer(answers);
  }

  void _addListItem(String questionId, List<String> items, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _listInputControllers[questionId]?.clear();
    _submitListAnswer([...items, trimmed]);
  }

  void _removeListItem(List<String> items, int index) {
    final updated = List<String>.from(items)..removeAt(index);
    _submitListAnswer(updated);
  }

  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => SubmitConfirmationDialog(
        answeredCount: context.read<ExamProvider>().answeredCount,
        totalQuestions: context.read<ExamProvider>().totalQuestions,
        onConfirm: _submitExam,
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _submitExam() async {
    _timer?.cancel();
    _syncTextAnswer();
    _persistCurrentInput();

    final examProvider = context.read<ExamProvider>();
    final result = await examProvider.completeExam();

    if (mounted) {
      final db = context.read<DatabaseProvider>();
      try {
        await db.analyticsRepository.createQuizResult(
          deckId: result.exam.deckId,
          totalQuestions: result.questions.length,
          correctAnswers: result.correctCount,
          score: result.percentage / 100,
          durationSeconds: result.totalTime.inSeconds,
          quizType: 'exam',
        );
        db.refreshAnalytics();
      } catch (e) {
        // Analytics persistence is best-effort; do not block exam flow.
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ExamResultScreen(
            examId: widget.examId,
          ),
        ),
      );
    }
  }

  void _persistCurrentInput() {
    final examProvider = context.read<ExamProvider>();
    final question = examProvider.currentQuestion;
    if (question == null) return;

    switch (question.type) {
      case QuestionType.identification:
      case QuestionType.mixedFormat:
        if (question.type == QuestionType.mixedFormat &&
            question.correctAnswers != null &&
            question.correctAnswers!.isNotEmpty) {
          break;
        }
        if (question.type == QuestionType.mixedFormat &&
            question.options.length >= 4) {
          break;
        }
        final controller = _textControllers[question.id];
        if (controller != null) {
          _submitTextAnswer(controller.text);
        }
        break;
      case QuestionType.enumeration:
        final current = examProvider.currentAnswers?.firstWhere(
          (a) => a.questionId == question.id,
          orElse: () => UserAnswer(
            questionId: question.id,
            isCorrect: false,
            answeredAt: DateTime.now(),
            timeSpent: Duration.zero,
          ),
        );
        final items = current?.listAnswer ?? <String>[];
        final listController = _listInputControllers[question.id];
        final pending = listController?.text.trim() ?? '';
        if (pending.isNotEmpty) {
          _submitListAnswer([...items, pending]);
        }
        break;
      case QuestionType.multipleChoice:
        break;
    }
  }

  void _showPauseDialog() {
    _timer?.cancel();
    _syncTextAnswer();
    _persistCurrentInput();
    showDialog(
      context: context,
      builder: (context) => PauseDialog(
        onResume: () {
          Navigator.of(context).pop();
          _startTimer();
        },
        onExit: () {
          Navigator.of(context).pop();
          _exitExam();
        },
      ),
    );
  }

  void _exitExam() {
    final examProvider = context.read<ExamProvider>();
    examProvider.abandonExam();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _textControllers.values) {
      c.dispose();
    }
    for (final c in _listInputControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showPauseDialog();
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Exam',
          actions: [
            _buildTimerDisplay(),
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: _showPauseDialog,
            ),
          ],
        ),
        body: Consumer<ExamProvider>(
          builder: (context, examProvider, child) {
            final question = examProvider.currentQuestion;

            if (question == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final answer = examProvider.currentAnswers?.firstWhere(
              (a) => a.questionId == question.id,
              orElse: () => UserAnswer(
                questionId: question.id,
                isCorrect: false,
                answeredAt: DateTime.now(),
                timeSpent: Duration.zero,
              ),
            );

            return Column(
              children: [
                _buildProgressBar(examProvider),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuestionNumber(examProvider),
                          const SizedBox(height: AppTheme.spacingLg),
                          _buildQuestionCard(question),
                          const SizedBox(height: AppTheme.spacingXl),
                          _buildAnswerOptions(question, answer, examProvider),
                          const SizedBox(height: AppTheme.spacingXl),
                          _buildNavigationButtons(examProvider),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Consumer<ExamProvider>(
      builder: (context, examProvider, child) {
        final remaining = examProvider.remainingTime;
        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;

        final isLow = remaining.inMinutes < 5;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingXs,
          ),
          decoration: BoxDecoration(
            color: isLow
                ? Colors.red.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 16,
                color: isLow
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: AppTheme.labelMedium.copyWith(
                  color: isLow
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(ExamProvider examProvider) {
    final progress = (examProvider.answeredCount / examProvider.totalQuestions).clamp(0.0, 1.0);

    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      valueColor: AlwaysStoppedAnimation<Color>(
        Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildQuestionNumber(ExamProvider examProvider) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingXs,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Text(
            'Question ${examProvider.currentQuestionIndex + 1}/${examProvider.totalQuestions}',
            style: AppTheme.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(ExamQuestion question) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: AppTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(
    ExamQuestion question,
    UserAnswer? answer,
    ExamProvider examProvider,
  ) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceOptions(question, answer);
      case QuestionType.identification:
        return _buildIdentificationInput(question, answer);
      case QuestionType.enumeration:
        return _buildEnumerationInput(question, answer);
      case QuestionType.mixedFormat:
        if (question.correctAnswers != null && question.correctAnswers!.isNotEmpty) {
          return _buildEnumerationInput(question, answer);
        }
        if (question.options.length >= 4) {
          return _buildMultipleChoiceOptions(question, answer);
        }
        return _buildIdentificationInput(question, answer);
    }
  }

  Widget _buildMultipleChoiceOptions(ExamQuestion question, UserAnswer? answer) {
    return Column(
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = answer?.selectedAnswerIndex == index;
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: InkWell(
            onTap: () => _selectAnswer(index),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: AppTheme.labelMedium.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Text(
                      option,
                      style: isSelected
                          ? AppTheme.bodyLarge.copyWith(color: colorScheme.onPrimaryContainer)
                          : AppTheme.bodyLarge,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIdentificationInput(ExamQuestion question, UserAnswer? answer) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        color: colorScheme.surface,
      ),
      child: TextField(
        controller: _textControllerFor(question.id, answer?.textAnswer ?? ''),
        decoration: InputDecoration(
          hintText: 'Enter your answer',
          border: InputBorder.none,
          hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
        style: AppTheme.bodyLarge,
        textInputAction: TextInputAction.done,
        onSubmitted: _submitTextAnswer,
      ),
    );
  }

  Widget _buildEnumerationInput(ExamQuestion question, UserAnswer? answer) {
    final items = answer?.listAnswer ?? <String>[];
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        color: colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter items (one at a time):',
            style: AppTheme.labelMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${index + 1}. $item',
                      style: AppTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => _removeListItem(items, index),
                  ),
                ],
              ),
            );
          }),
          TextField(
            controller: _listInputControllerFor(question.id),
            decoration: InputDecoration(
              hintText: 'Add item ${items.length + 1}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingXs,
              ),
            ),
            style: AppTheme.bodyMedium,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => _addListItem(question.id, items, value),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ExamProvider examProvider) {
    final isLastQuestion = examProvider.currentQuestionIndex >= examProvider.totalQuestions - 1;

    return Row(
      children: [
        if (examProvider.currentQuestionIndex > 0)
          Expanded(
            child: CustomButton(
              text: 'Previous',
              onPressed: () {
                _persistCurrentInput();
                examProvider.goToPreviousQuestion();
              },
              isOutlined: true,
              icon: Icons.arrow_back,
            ),
          ),
        if (examProvider.currentQuestionIndex > 0)
          const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: CustomButton(
            text: isLastQuestion ? 'Finish Exam' : 'Next',
            onPressed: () {
              _persistCurrentInput();
              if (isLastQuestion) {
                _showSubmitConfirmation();
              } else {
                examProvider.goToNextQuestion();
              }
            },
            icon: isLastQuestion ? Icons.check : Icons.arrow_forward,
          ),
        ),
      ],
    );
  }
}
