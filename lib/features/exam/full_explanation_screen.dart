import 'package:flutter/material.dart';
import '../../core/models/exam.dart';
import '../../core/utils/explanation_sanitizer.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/formatted_study_text.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';

class FullExplanationScreen extends StatelessWidget {
  final ExamQuestion question;
  final String? explanation;

  const FullExplanationScreen({
    super.key,
    required this.question,
    this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Full Explanation',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionCard(context),
            const SizedBox(height: AppTheme.spacingXl),
            _buildAnswerAnalysis(context),
            const SizedBox(height: AppTheme.spacingXl),
            _buildExplanationCard(context),
            const SizedBox(height: AppTheme.spacingXl),
            _buildKeyConcepts(context),
            const SizedBox(height: AppTheme.spacingXl),
            _buildRelatedInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  'Question',
                  style: AppTheme.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            question.question,
            style: AppTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerAnalysis(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Answer Analysis',
            style: AppTheme.labelLarge,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildAnswerOption(
            context,
            index: question.correctAnswerIndex,
            text: question.correctAnswer,
            isCorrect: true,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...question.options.asMap().entries.where((e) => e.key != question.correctAnswerIndex).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: _buildAnswerOption(
                context,
                index: entry.key,
                text: entry.value,
                isCorrect: false,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(
    BuildContext context, {
    required int index,
    required String text,
    required bool isCorrect,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: isCorrect
            ? colorScheme.primaryContainer
            : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isCorrect
              ? colorScheme.primary
              : colorScheme.error,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCorrect
                  ? colorScheme.primary
                  : colorScheme.error,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index),
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect
                          ? colorScheme.primary
                          : colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      isCorrect ? 'Correct Answer' : 'Incorrect Option',
                      style: AppTheme.labelMedium.copyWith(
                        color: isCorrect
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  text,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context) {
    if (explanation == null) {
      return CustomCard(
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No explanation available',
              style: AppTheme.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'AI Explanation',
                style: AppTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          FormattedStudyText(
            text: ExplanationSanitizer.sanitize(explanation),
            style: AppTheme.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            showActions: true,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyConcepts(BuildContext context) {
    // Extract key concepts from the explanation (simplified version)
    final concepts = _extractKeyConcepts();

    if (concepts.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Key Concepts',
                style: AppTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            children: concepts.map((concept) {
              return Chip(
                label: Text(concept),
                backgroundColor: colorScheme.tertiaryContainer,
                side: BorderSide(color: colorScheme.tertiary),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Study Tip',
                style: AppTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Review similar questions to reinforce your understanding of this topic. '
            'Consider creating flashcards for concepts you find challenging.',
            style: AppTheme.bodyLarge.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractKeyConcepts() {
    // Simple concept extraction - in a real app, this would be more sophisticated
    if (explanation == null) return [];

    final concepts = <String>[];
    final words = explanation!.split(' ');
    
    // Look for capitalized words that might be concepts
    for (final word in words) {
      if (word.length > 3 && 
          word[0] == word[0].toUpperCase() &&
          word[1] != word[1].toUpperCase()) {
        final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
        if (cleanWord.isNotEmpty && !concepts.contains(cleanWord)) {
          concepts.add(cleanWord);
        }
      }
    }

    return concepts.take(5).toList();
  }
}
