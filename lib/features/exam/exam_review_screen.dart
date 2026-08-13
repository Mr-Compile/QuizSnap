import 'package:flutter/material.dart';
import '../../core/models/exam.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';
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
  ReviewFilter _currentFilter = ReviewFilter.all;

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Review Answers',
          leading: const BackButton(),
          bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Correct'),
            Tab(text: 'Incorrect'),
          ],
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _currentFilter = ReviewFilter.all;
                  break;
                case 1:
                  _currentFilter = ReviewFilter.correct;
                  break;
                case 2:
                  _currentFilter = ReviewFilter.incorrect;
                  break;
              }
            });
          },
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
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
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ReviewFilter.values.map((filter) {
            final isSelected = _currentFilter == filter;
            final count = _getCountForFilter(filter);

            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSm),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(filter.label),
                    if (count > 0) ...[
                      const SizedBox(width: AppTheme.spacingXs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3)
                              : Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: AppTheme.bodySmall.copyWith(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _currentFilter = filter);
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  int _getCountForFilter(ReviewFilter filter) {
    switch (filter) {
      case ReviewFilter.correct:
        return widget.result.correctQuestions.length;
      case ReviewFilter.incorrect:
        return widget.result.incorrectQuestions.length;
      case ReviewFilter.unanswered:
        return widget.result.unansweredQuestions.length;
      case ReviewFilter.all:
        return widget.result.questions.length;
    }
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
      case ReviewFilter.unanswered:
        return widget.result.unansweredQuestions;
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
      case ReviewFilter.unanswered:
        return Icons.help_outline;
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
      case ReviewFilter.unanswered:
        return 'No unanswered questions';
      case ReviewFilter.all:
        return 'No questions to review';
    }
  }

  Widget _buildQuestionCard(ExamQuestion question, UserAnswer answer, int index) {
    final isCorrect = answer.isCorrect;
    final isUnanswered = answer.selectedAnswerIndex == null;

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
    return Column(
      children: question.options.asMap().entries.map((entry) {
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
      }).toList(),
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
  unanswered,
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
      case ReviewFilter.unanswered:
        return 'Unanswered';
    }
  }
}
