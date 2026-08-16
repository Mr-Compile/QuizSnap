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
  final UserAnswer? userAnswer;

  const FullExplanationScreen({
    super.key,
    required this.question,
    this.explanation,
    this.userAnswer,
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

  String _getUserAnswerText() {
    if (userAnswer == null) return 'No answer';

    final selectedIndex = userAnswer!.selectedAnswerIndex;
    if (selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < question.options.length) {
      return question.options[selectedIndex];
    }

    if (userAnswer!.textAnswer != null && userAnswer!.textAnswer!.trim().isNotEmpty) {
      return userAnswer!.textAnswer!.trim();
    }

    if (userAnswer!.listAnswer != null && userAnswer!.listAnswer!.isNotEmpty) {
      return userAnswer!.listAnswer!.join(', ');
    }

    return 'No answer';
  }

  bool get _hasUserAnswer {
    return userAnswer != null && userAnswer!.hasAnswer;
  }

  Widget _buildAnswerAnalysis(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userAnswerText = _getUserAnswerText();
    final correctAnswerText = question.correctAnswerText;
    final isUserCorrect = _hasUserAnswer && (userAnswer?.isCorrect ?? false);
    final userColor = _hasUserAnswer
        ? (isUserCorrect ? colorScheme.primary : colorScheme.error)
        : colorScheme.onSurface;
    final userIcon = _hasUserAnswer
        ? (isUserCorrect ? Icons.check_circle : Icons.cancel)
        : Icons.help;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Answer Analysis',
            style: AppTheme.labelLarge,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildAnswerSummary(
            context,
            label: 'Your answer',
            value: userAnswerText,
            color: userColor,
            icon: userIcon,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildAnswerSummary(
            context,
            label: 'Correct answer',
            value: correctAnswerText,
            color: colorScheme.primary,
            icon: Icons.check_circle,
          ),
          if (question.options.length >= 2) ...[
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Options',
              style: AppTheme.labelMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ..._buildOptionsList(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerSummary(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  value,
                  style: AppTheme.bodyLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
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

  List<Widget> _buildOptionsList(BuildContext context) {
    final userSelectedIndex = userAnswer?.selectedAnswerIndex;
    return question.options.asMap().entries.map((entry) {
      return _buildAnswerOption(
        context,
        index: entry.key,
        text: entry.value,
        isCorrect: entry.key == question.correctAnswerIndex,
        isSelected: entry.key == userSelectedIndex,
      );
    }).toList();
  }

  Widget _buildAnswerOption(
    BuildContext context, {
    required int index,
    required String text,
    required bool isCorrect,
    bool isSelected = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isCorrect
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final borderColor = isCorrect
        ? colorScheme.primary
        : colorScheme.outline.withValues(alpha: 0.3);
    final badgeColor = isCorrect ? colorScheme.primary : colorScheme.onSurface;
    final badgeText = isCorrect
        ? 'Correct Answer'
        : isSelected
            ? 'Your answer'
            : '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: borderColor,
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
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: isCorrect ? colorScheme.primary : colorScheme.outline,
              ),
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index),
                style: TextStyle(
                  color: isCorrect
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
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
                if (badgeText.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.radio_button_checked,
                        color: badgeColor,
                        size: 18,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        badgeText,
                        style: AppTheme.labelSmall.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (badgeText.isNotEmpty)
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
    if (explanation == null || explanation!.trim().isEmpty) {
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
                Icons.psychology_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'AI Explanation',
                style: AppTheme.titleMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
