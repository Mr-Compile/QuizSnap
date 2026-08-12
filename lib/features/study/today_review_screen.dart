import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'flashcard_card_screen.dart';

class TodayReviewScreen extends StatefulWidget {
  const TodayReviewScreen({super.key});

  @override
  State<TodayReviewScreen> createState() => _TodayReviewScreenState();
}

class _TodayReviewScreenState extends State<TodayReviewScreen> {
  List<Flashcard> _dueCards = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  int _incorrectCount = 0;
  bool _isStarted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Today\'s Review',
        actions: [
          if (_isStarted)
            TextButton(
              onPressed: () => _showSummary(context),
              child: const Text('Finish'),
            ),
        ],
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: dbProvider.studyRepository.getDueFlashcards(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final dueCards = snapshot.data ?? [];

              if (!_isStarted) {
                if (dueCards.isEmpty) {
                  return EmptyState(
                    icon: Icons.check_circle,
                    title: 'All caught up!',
                    subtitle: 'No cards due for review today',
                  );
                }

                return _buildStartScreen(context, dueCards);
              }

              if (_dueCards.isEmpty) {
                return _buildSummaryScreen(context);
              }

              return FlashcardCardScreen(
                flashcards: _dueCards,
                currentIndex: _currentIndex,
                onCardRated: (quality) => _handleCardRated(context, quality),
                onPrevious: () => setState(() => _currentIndex--),
                onNext: () => setState(() => _currentIndex++),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStartScreen(BuildContext context, List<Flashcard> dueCards) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.today,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  '${dueCards.length} cards due',
                  style: AppTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Review your cards to reinforce your memory using spaced repetition.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _startReview(dueCards),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
              ),
              child: const Text('Start Review'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryScreen(BuildContext context) {
    final total = _correctCount + _incorrectCount;
    final accuracy = total > 0 ? (_correctCount / total * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'Review Complete!',
                  style: AppTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryStat(
                        context,
                        'Correct',
                        _correctCount.toString(),
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryStat(
                        context,
                        'Incorrect',
                        _incorrectCount.toString(),
                        Colors.red,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryStat(
                        context,
                        'Accuracy',
                        '$accuracy%',
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
              ),
              child: const Text('Back to Study'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.headlineSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  void _startReview(List<Flashcard> dueCards) {
    setState(() {
      _dueCards = dueCards;
      _currentIndex = 0;
      _correctCount = 0;
      _incorrectCount = 0;
      _isStarted = true;
    });
  }

  void _handleCardRated(BuildContext context, int quality) {
    final flashcard = _dueCards[_currentIndex];
    
    // Update card using SM-2 algorithm
    context.read<DatabaseProvider>().studyRepository.updateCardReview(
      flashcard.id,
      quality,
    );

    // Track statistics
    if (quality >= 3) {
      _correctCount++;
    } else {
      _incorrectCount++;
    }

    // Move to next card or show summary
    if (_currentIndex < _dueCards.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      setState(() {
        _dueCards = [];
      });
    }
  }

  void _showSummary(BuildContext context) {
    setState(() {
      _dueCards = [];
    });
  }
}