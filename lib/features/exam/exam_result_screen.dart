import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/exam_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/exam.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';
import 'exam_review_screen.dart';

class ExamResultScreen extends StatefulWidget {
  final String examId;

  const ExamResultScreen({
    super.key,
    required this.examId,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  ExamResult? _result;

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  Future<void> _loadResult() async {
    final examProvider = context.read<ExamProvider>();
    final exam = examProvider.currentExam;
    final questions = examProvider.currentQuestions;
    final answers = examProvider.currentAnswers;

    if (exam != null && questions != null && answers != null) {
      final correctCount = answers.where((a) => a.isCorrect).length;
      final incorrectCount = answers.where((a) => !a.isCorrect && a.selectedAnswerIndex != null).length;
      final unansweredCount = questions.where((q) {
        final answer = answers.firstWhere(
          (a) => a.questionId == q.id,
          orElse: () => UserAnswer(
            questionId: q.id,
            isCorrect: false,
            answeredAt: DateTime.now(),
            timeSpent: Duration.zero,
          ),
        );
        return answer.selectedAnswerIndex == null;
      }).length;
      final percentage = questions.isNotEmpty
          ? (correctCount / questions.length) * 100
          : 0.0;

      setState(() {
        _result = ExamResult(
          exam: exam,
          questions: questions,
          answers: answers,
          correctCount: correctCount,
          incorrectCount: incorrectCount,
          unansweredCount: unansweredCount,
          percentage: percentage,
          totalTime: exam.elapsed,
        );
      });
    }
  }

  Color _getGradeColor(BuildContext context, double percentage) {
    final colors = Theme.of(context).colorScheme;
    if (percentage >= 90) return colors.primary;
    if (percentage >= 80) return colors.secondary;
    if (percentage >= 70) return colors.tertiary;
    if (percentage >= 60) return colors.onSurfaceVariant;
    return colors.error;
  }

  Color _getGradeOnColor(BuildContext context, double percentage) {
    final colors = Theme.of(context).colorScheme;
    if (percentage >= 90) return colors.onPrimary;
    if (percentage >= 80) return colors.onSecondary;
    if (percentage >= 70) return colors.onTertiary;
    if (percentage >= 60) return colors.surface;
    return colors.onError;
  }

  @override
  Widget build(BuildContext context) {
    if (_result == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final result = _result!;
    final gradeColor = _getGradeColor(context, result.percentage);

    void backToDeck() => context.go('/decks/${result.exam.deckId}');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) backToDeck();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Exam Results',
          leading: BackButton(
            onPressed: backToDeck,
          ),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            _buildScoreCard(result, gradeColor),
            const SizedBox(height: AppTheme.spacingXl),
            _buildStatisticsCard(result),
            const SizedBox(height: AppTheme.spacingXl),
            _buildTimeCard(result),
            const SizedBox(height: AppTheme.spacingXl),
            _buildActionButtons(result),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildScoreCard(ExamResult result, Color gradeColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradeColor.withValues(alpha: 0.2),
            gradeColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            _getGradeIcon(result.percentage),
            size: 64,
            color: gradeColor,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            '${result.percentage.toStringAsFixed(1)}%',
            style: AppTheme.headlineLarge.copyWith(
              color: gradeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: gradeColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Text(
              'Grade: ${result.grade} - ${result.gradeLabel}',
              style: AppTheme.titleLarge.copyWith(
                color: _getGradeOnColor(context, result.percentage),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            result.exam.deckName,
            style: AppTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getGradeIcon(double percentage) {
    if (percentage >= 90) return Icons.emoji_events;
    if (percentage >= 80) return Icons.thumb_up;
    if (percentage >= 70) return Icons.sentiment_satisfied;
    if (percentage >= 60) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  Widget _buildStatisticsCard(ExamResult result) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: AppTheme.labelLarge,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildStatRow(
            Icons.check_circle,
            'Correct',
            '${result.correctCount}',
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildStatRow(
            Icons.cancel,
            'Incorrect',
            '${result.incorrectCount}',
            Theme.of(context).colorScheme.error,
            Theme.of(context).colorScheme.errorContainer,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildStatRow(
            Icons.help_outline,
            'Unanswered',
            '${result.unansweredCount}',
            Theme.of(context).colorScheme.tertiary,
            Theme.of(context).colorScheme.tertiaryContainer,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: LinearProgressIndicator(
              value: result.correctCount / result.questions.length,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '${(result.correctCount / result.questions.length * 100).toStringAsFixed(1)}% Correct',
            style: AppTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color, Color containerColor) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: AppTheme.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCard(ExamResult result) {
    final hours = result.totalTime.inHours;
    final minutes = result.totalTime.inMinutes % 60;
    final seconds = result.totalTime.inSeconds % 60;

    String timeString;
    if (hours > 0) {
      timeString = '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      timeString = '${minutes}m ${seconds}s';
    } else {
      timeString = '${seconds}s';
    }

    return CustomCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              Icons.timer,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time Taken',
                  style: AppTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  timeString,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ExamResult result) {
    return Column(
      children: [
        CustomButton(
          text: 'Review Answers',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ExamReviewScreen(
                  result: result,
                ),
              ),
            );
          },
          icon: Icons.rate_review,
          fullWidth: true,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        CustomButton(
          text: 'Back to Deck',
          onPressed: () {
            final examProvider = context.read<ExamProvider>();
            examProvider.clearExam();
            if (mounted) {
              context.go('/decks/${result.exam.deckId}');
            }
          },
          isOutlined: true,
          fullWidth: true,
        ),
      ],
    );
  }
}
