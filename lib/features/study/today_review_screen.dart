import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'flashcard_study_session_screen.dart';

class TodayReviewScreen extends StatefulWidget {
  const TodayReviewScreen({super.key});

  @override
  State<TodayReviewScreen> createState() => _TodayReviewScreenState();
}

class _TodayReviewScreenState extends State<TodayReviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Today\'s Review',
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

              if (dueCards.isEmpty) {
                return EmptyState(
                  icon: Icons.check_circle,
                  title: 'All caught up!',
                  subtitle: 'No cards due for review today',
                );
              }

              return _buildStartScreen(context, dueCards);
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
                  color: const Color(0xFF3B82F6), // Blue
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

  void _startReview(List<Flashcard> dueCards) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardStudySessionScreen(
          deckName: 'Today\'s Review',
          deckId: 0,
          flashcards: dueCards,
        ),
      ),
    );
  }
}