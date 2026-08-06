import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/loading_skeleton.dart';
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Bookmarked',
                  stats.bookmarked.toString(),
                  Icons.bookmark,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Accuracy',
                  '${stats.accuracy}%',
                  Icons.check_circle,
                  Colors.green,
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
            color: color.withOpacity(0.1),
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        CustomCard(
          onTap: stats.dueToday > 0
              ? () => _navigateToTodayReview(context)
              : null,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: stats.dueToday > 0
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.today,
                  color: stats.dueToday > 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
                      stats.dueToday > 0
                          ? '$stats.dueToday cards due'
                          : 'No cards due today',
                      style: AppTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (stats.dueToday > 0)
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudyModes(BuildContext context) {
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.bookmark,
                  color: Colors.blue,
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.style,
                  color: Colors.purple,
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ],
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