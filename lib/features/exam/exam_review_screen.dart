import 'package:flutter/material.dart';
import '../../core/models/exam.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';
import 'package:intl/intl.dart';
import 'answer_explanation_bottom_sheet.dart';

class ExamReviewScreen extends StatefulWidget {
  final ExamResult result;

  const ExamReviewScreen({
    super.key,
    required this.result,
  });

  @override
  State<ExamReviewScreen> createState() => _ExamReviewScreenState();
}

class _ExamReviewScreenState extends State<ExamReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void navigateBack() {
      Navigator.of(context).pop();
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Review Answers',
          leading: BackButton(
            onPressed: navigateBack,
          ),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildReviewHeader(context),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Correct'),
                  Tab(text: 'Incorrect'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQuestionsList(ReviewFilter.all),
                    _buildQuestionsList(ReviewFilter.correct),
                    _buildQuestionsList(ReviewFilter.incorrect),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateTaken = widget.result.exam.completedAt ?? widget.result.exam.createdAt;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.result.exam.deckName,
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                Icon(Icons.score, color: colorScheme.primary, size: 18),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Score: ${widget.result.percentage.toStringAsFixed(1)}%',
                  style: AppTheme.bodyLarge.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                Icon(Icons.calendar_today, color: colorScheme.onSurfaceVariant, size: 18),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                'Date taken: ${DateFormat.yMMMd().format(dateTaken)}',
                style: AppTheme.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList(ReviewFilter filter) {
    final questions = _getQuestionsForFilter(filter);

    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyIcon(filter),
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              _getEmptyMessage(filter),
              style: AppTheme.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        final answer = widget.result.answers.firstWhere(
          (a) => a.questionId == question.id,
          orElse: () => UserAnswer(
            questionId: question.id,
            isCorrect: false,
            answeredAt: DateTime.now(),
            timeSpent: Duration.zero,
          ),
        );

        return _buildQuestionCard(question, answer, index);
      },
    );
  }

  List<ExamQuestion> _getQuestionsForFilter(ReviewFilter filter) {
    switch (filter) {
      case ReviewFilter.correct:
        return widget.result.correctQuestions;
      case ReviewFilter.incorrect:
        return widget.result.incorrectQuestions;
      case ReviewFilter.all:
        return widget.result.questions;
    }
  }

  IconData _getEmptyIcon(ReviewFilter filter) {
    switch (filter) {
      case ReviewFilter.correct:
        return Icons.check_circle_outline;
      case ReviewFilter.incorrect:
        return Icons.cancel_outlined;
      case ReviewFilter.all:
        return Icons.quiz_outlined;
    }
  }

  String _getEmptyMessage(ReviewFilter filter) {
    switch (filter) {
      case ReviewFilter.correct:
        return 'No correct answers';
      case ReviewFilter.incorrect:
        return 'No incorrect answers';
      case ReviewFilter.all:
        return 'No questions to review';
    }
  }

  Widget _buildQuestionCard(ExamQuestion question, UserAnswer answer, int index) {
    final isCorrect = answer.isCorrect;
    final isUnanswered = (answer.selectedAnswerIndex == null) &&
        (answer.textAnswer == null || answer.textAnswer!.isEmpty) &&
        (answer.listAnswer == null || answer.listAnswer!.isEmpty);

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCorrect
                      ? Theme.of(context).colorScheme.primary
                      : isUnanswered
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  question.question,
                  style: AppTheme.labelLarge,
                ),
              ),
              Icon(
                isCorrect
                    ? Icons.check_circle
                    : isUnanswered
                        ? Icons.help
                        : Icons.cancel,
                color: isCorrect
                    ? Theme.of(context).colorScheme.primary
                    : isUnanswered
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildAnswerOptions(question, answer),
          const SizedBox(height: AppTheme.spacingMd),
          _buildExplanationButton(question),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(ExamQuestion question, UserAnswer answer) {
    // Render different UI based on question type
    switch (question.type) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceReview(question, answer);
      case QuestionType.identification:
        return _buildIdentificationReview(question, answer);
      case QuestionType.enumeration:
        return _buildEnumerationReview(question, answer);
      case QuestionType.mixedFormat:
        // For mixed format, check if it has options or text answer
        if (question.options.length >= 4) {
          return _buildMultipleChoiceReview(question, answer);
        } else {
          return _buildIdentificationReview(question, answer);
        }
    }
  }

  Widget _buildMultipleChoiceReview(ExamQuestion question, UserAnswer answer) {
    return Column(
      children: [
        ...question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isCorrectAnswer = index == question.correctAnswerIndex;
        final isSelected = answer.selectedAnswerIndex == index;
        final isUnanswered = answer.selectedAnswerIndex == null;

        final colorScheme = Theme.of(context).colorScheme;
        Color? backgroundColor;
        Color? borderColor;
        Color? labelColor;
        IconData? trailingIcon;

        if (isCorrectAnswer) {
          backgroundColor = colorScheme.primaryContainer;
          borderColor = colorScheme.primary;
          labelColor = colorScheme.onPrimaryContainer;
          trailingIcon = Icons.check;
        } else if (isSelected && !isUnanswered) {
          backgroundColor = colorScheme.errorContainer;
          borderColor = colorScheme.error;
          labelColor = colorScheme.onErrorContainer;
          trailingIcon = Icons.close;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingXs),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor ?? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            color: backgroundColor,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor == colorScheme.primary
                      ? colorScheme.primaryContainer
                      : borderColor == colorScheme.error
                          ? colorScheme.errorContainer
                          : colorScheme.surfaceContainerHighest,
                  border: Border.all(color: borderColor ?? colorScheme.outline),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: labelColor ?? colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  option,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: isCorrectAnswer ? FontWeight.bold : FontWeight.normal,
                    color: labelColor ?? colorScheme.onSurface,
                  ),
                ),
              ),
              if (trailingIcon != null)
                Icon(
                  trailingIcon,
                  color: borderColor,
                  size: 20,
                ),
            ],
          ),
        );
      }),
      if (answer.selectedAnswerIndex == null)
        Padding(
          padding: const EdgeInsets.only(top: AppTheme.spacingMd),
          child: Text(
            'No answer submitted.',
            style: AppTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
    ],
    );
  }

  Widget _buildIdentificationReview(ExamQuestion question, UserAnswer answer) {
    final colorScheme = Theme.of(context).colorScheme;
    final userAnswer = (answer.textAnswer?.isNotEmpty == true)
        ? answer.textAnswer!
        : 'No answer submitted.';
    final correctAnswer = question.correctAnswer ?? '';
    final isCorrect = answer.isCorrect;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReviewRow(
          'Your Answer',
          userAnswer,
          isCorrect ? colorScheme.primary : colorScheme.error,
          isCorrect ? Icons.check : Icons.close,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        _buildReviewRow(
          'Correct Answer',
          correctAnswer,
          colorScheme.primary,
          Icons.check_circle,
        ),
      ],
    );
  }

  Widget _buildEnumerationReview(ExamQuestion question, UserAnswer answer) {
    final colorScheme = Theme.of(context).colorScheme;
    final userAnswers = answer.listAnswer ?? <String>[];
    final correctAnswers = question.correctAnswers ?? <String>[];

    // Find missing items
    final missingItems = correctAnswers
        .where((correct) => !userAnswers.any((user) => 
            user.toLowerCase().trim() == correct.toLowerCase().trim()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Answers:',
          style: AppTheme.labelMedium.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        ...userAnswers.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: colorScheme.onSurface,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  item,
                  style: AppTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )),
        if (userAnswers.isEmpty)
          Text(
            'No answer submitted.',
            style: AppTheme.bodyMedium.copyWith(
              color: colorScheme.error,
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          'Correct Answers:',
          style: AppTheme.labelMedium.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        ...correctAnswers.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  item,
                  style: AppTheme.bodyMedium.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        )),
        if (missingItems.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingMd),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: colorScheme.error),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      'Missing Items:',
                      style: AppTheme.labelSmall.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                ...missingItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
                  child: Text(
                    '• $item',
                    style: AppTheme.bodySmall.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            '$label:',
            style: AppTheme.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationButton(ExamQuestion question) {
    return CustomButton(
      text: 'View Explanation',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AnswerExplanationBottomSheet(
            question: question,
          ),
        );
      },
      isOutlined: true,
      icon: Icons.lightbulb_outline,
      fullWidth: true,
    );
  }
}

enum ReviewFilter {
  all,
  correct,
  incorrect,
}

extension ReviewFilterExtension on ReviewFilter {
  String get label {
    switch (this) {
      case ReviewFilter.all:
        return 'All';
      case ReviewFilter.correct:
        return 'Correct';
      case ReviewFilter.incorrect:
        return 'Incorrect';
    }
  }
}
