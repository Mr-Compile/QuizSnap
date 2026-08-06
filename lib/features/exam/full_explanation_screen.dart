import 'package:flutter/material.dart';
import '../../core/models/exam.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
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
            _buildQuestionCard(),
            const SizedBox(height: AppTheme.spacingXl),
            _buildAnswerAnalysis(),
            const SizedBox(height: AppTheme.spacingXl),
            _buildExplanationCard(),
            const SizedBox(height: AppTheme.spacingXl),
            _buildKeyConcepts(),
            const SizedBox(height: AppTheme.spacingXl),
            _buildRelatedInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
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
            style: AppTheme.textLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerAnalysis() {
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
            index: question.correctAnswerIndex,
            text: question.correctAnswer,
            isCorrect: true,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...question.options.asMap().entries.where((e) => e.key != question.correctAnswerIndex).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: _buildAnswerOption(
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

  Widget _buildAnswerOption({
    required int index,
    required String text,
    required bool isCorrect,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: isCorrect 
            ? AppTheme.emerald50 
            : AppTheme.red50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isCorrect 
              ? AppTheme.emerald600 
              : AppTheme.red600,
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
                  ? AppTheme.emerald600 
                  : AppTheme.red600,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index),
                style: const TextStyle(
                  color: Colors.white,
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
                          ? AppTheme.emerald600 
                          : AppTheme.red600,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      isCorrect ? 'Correct Answer' : 'Incorrect Option',
                      style: AppTheme.labelMedium.copyWith(
                        color: isCorrect 
                            ? AppTheme.emerald700 
                            : AppTheme.red700,
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

  Widget _buildExplanationCard() {
    if (explanation == null) {
      return CustomCard(
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No explanation available',
              style: AppTheme.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
          Text(
            explanation!,
            style: AppTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyConcepts() {
    // Extract key concepts from the explanation (simplified version)
    final concepts = _extractKeyConcepts();

    if (concepts.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: AppTheme.amber600,
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
                backgroundColor: AppTheme.amber50,
                side: BorderSide(color: AppTheme.amber600),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedInfo() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: Theme.of(context).colorScheme.primary,
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
