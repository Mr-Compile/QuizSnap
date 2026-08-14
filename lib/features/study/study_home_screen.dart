import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/study_session_controller.dart';
import '../../core/services/study_session_persistence.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'flashcard_study_session_screen.dart';
import 'today_review_screen.dart';
import 'bookmark_list_screen.dart';
import 'deck_study_screen.dart';

class StudyHomeScreen extends StatefulWidget {
  const StudyHomeScreen({super.key});

  @override
  State<StudyHomeScreen> createState() => _StudyHomeScreenState();
}

class _StudyHomeScreenState extends State<StudyHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Study',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: dbProvider.studyRepository.getStudyStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final stats = snapshot.data!;
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(context),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildStatsCard(context, stats),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildContinueSession(context),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildQuickActions(context, stats),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildStudyModes(context),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: AppTheme.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          'Ready to study?',
          style: AppTheme.headlineMedium,
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, stats) {
    final dueTodayColor = const Color(0xFF3B82F6); // Blue
    final bookmarkedColor = const Color(0xFFF59E0B); // Amber
    final accuracyColor = const Color(0xFF22C55E); // Green
    
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Progress',
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Due Today',
                  stats.dueToday.toString(),
                  Icons.assignment,
                  dueTodayColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Bookmarked',
                  stats.bookmarked.toString(),
                  Icons.bookmark,
                  bookmarkedColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Accuracy',
                  '${stats.accuracy}%',
                  Icons.check_circle,
                  accuracyColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
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

  Widget _buildQuickActions(BuildContext context, stats) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDue = stats.dueToday > 0;
    final todayReviewColor = AppTheme.blue500;
    final inactiveColor = colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        CustomCard(
          onTap: hasDue
              ? () => _navigateToTodayReview(context)
              : null,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: hasDue
                      ? todayReviewColor.withValues(alpha: 0.1)
                      : inactiveColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.today,
                      color: hasDue ? todayReviewColor : inactiveColor,
                    ),
                    if (hasDue)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: todayReviewColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '${stats.dueToday}',
                            style: AppTheme.bodySmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Review',
                      style: AppTheme.labelLarge,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      hasDue
                          ? '${stats.dueToday} cards due'
                          : 'No cards due today',
                      style: AppTheme.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasDue)
                Icon(
                  Icons.chevron_right,
                  color: todayReviewColor.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudyModes(BuildContext context) {
    final bookmarksColor = const Color(0xFFF59E0B); // Amber/Orange
    final deckStudyColor = const Color(0xFF8B5CF6); // Purple
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Study Modes',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        CustomCard(
          onTap: () => _navigateToBookmarks(context),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: bookmarksColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.bookmark,
                  color: bookmarksColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bookmarks',
                      style: AppTheme.labelLarge,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Study your favorite cards',
                      style: AppTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: bookmarksColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        CustomCard(
          onTap: () => _navigateToDeckStudy(context),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: deckStudyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.style,
                  color: deckStudyColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study by Deck',
                      style: AppTheme.labelLarge,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Choose a deck to study',
                      style: AppTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: deckStudyColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueSession(BuildContext context) {
    final continueSessionColor = const Color(0xFF22C55E); // Green
    
    return Selector<StudySessionController, bool>(
      selector: (context, controller) =>
          controller.persistence?.hasUnfinishedSession ?? false,
      builder: (context, hasSession, _) {
        if (!hasSession) return const SizedBox.shrink();

        final state = context.read<StudySessionController>().persistence!.load()!;
        final progress = '${state.currentIndex + 1} / ${state.totalCards}';

        return CustomCard(
          onTap: () => _continueSession(context, state),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: continueSessionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: continueSessionColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue Last Session',
                      style: AppTheme.labelLarge,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      state.deckName,
                      style: AppTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      '$progress • ${_formatRelativeTime(state.lastStudiedAt)}',
                      style: AppTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: continueSessionColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatRelativeTime(DateTime? time) {
    if (time == null) return 'unknown time';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _continueSession(BuildContext context, StudySessionState state) async {
    final db = context.read<DatabaseProvider>();
    final flashcards = await db.flashcardRepository.getFlashcardsByDeck(state.deckId);
    if (flashcards.isEmpty) return;

    if (!mounted) return;
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardStudySessionScreen(
          flashcards: flashcards,
          deckId: state.deckId,
          deckName: state.deckName,
          initialIndex: state.currentIndex,
          initialRevealed: state.isRevealed,
        ),
      ),
    );
  }

  void _navigateToTodayReview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TodayReviewScreen(),
      ),
    );
  }

  void _navigateToBookmarks(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BookmarkListScreen(),
      ),
    );
  }

  void _navigateToDeckStudy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DeckStudyScreen(),
      ),
    );
  }
}