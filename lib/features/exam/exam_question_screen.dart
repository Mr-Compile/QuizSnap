import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/exam_provider.dart';
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
  int? _selectedAnswerIndex;

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time Expired'),
        content: const Text('Your exam time has expired. Your answers will be submitted automatically.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submitExam();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(int index) {
    setState(() => _selectedAnswerIndex = index);
  }

  void _submitAnswer() {
    if (_selectedAnswerIndex == null) return;

    final examProvider = context.read<ExamProvider>();
    examProvider.submitAnswer(_selectedAnswerIndex!);
    setState(() => _selectedAnswerIndex = null);

    // Auto-advance to next question
    if (examProvider.currentQuestionIndex < examProvider.totalQuestions - 1) {
      examProvider.goToNextQuestion();
    } else {
      // Last question - show submit confirmation
      _showSubmitConfirmation();
    }
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
    
    final examProvider = context.read<ExamProvider>();
    await examProvider.completeExam();

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

  void _showPauseDialog() {
    _timer?.cancel();
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
    final examProvider = context.read<ExamProvider();
    examProvider.abandonExam();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goToQuestion(int index) {
    final examProvider = context.read<ExamProvider>();
    
    // Check if current question has been answered
    if (_selectedAnswerIndex != null) {
      examProvider.submitAnswer(_selectedAnswerIndex!);
      setState(() => _selectedAnswerIndex = null);
    }
    
    examProvider.goToQuestion(index);
  }

  @override
  void dispose() {
    _timer?.cancel();
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

            return Column(
              children: [
                _buildProgressBar(examProvider),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuestionNumber(examProvider),
                        const SizedBox(height: AppTheme.spacingLg),
                        _buildQuestionCard(question),
                        const SizedBox(height: AppTheme.spacingXl),
                        _buildAnswerOptions(question),
                        const SizedBox(height: AppTheme.spacingXl),
                        _buildNavigationButtons(examProvider),
                      ],
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
                ? Colors.red.withOpacity(0.1)
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
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
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
            style: AppTheme.textLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(ExamQuestion question) {
    return Column(
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _selectedAnswerIndex == index;

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
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceVariant,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: AppTheme.labelMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Text(
                      option,
                      style: AppTheme.bodyLarge,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
                if (_selectedAnswerIndex != null) {
                  examProvider.submitAnswer(_selectedAnswerIndex!);
                  setState(() => _selectedAnswerIndex = null);
                }
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
            onPressed: _selectedAnswerIndex != null
                ? isLastQuestion
                    ? _showSubmitConfirmation
                    : _submitAnswer
                : null,
            icon: isLastQuestion ? Icons.check : Icons.arrow_forward,
          ),
        ),
      ],
    );
  }
}
