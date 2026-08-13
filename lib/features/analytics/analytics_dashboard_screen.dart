import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'daily_activity_chart_screen.dart';
import 'quiz_performance_screen.dart';
import 'mastery_breakdown_screen.dart';
import 'weak_topics_screen.dart';
import 'study_time_screen.dart';
import 'subject_accuracy_screen.dart';
import 'insights_screen.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Analytics',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: dbProvider.analyticsRepository.getAnalyticsSummary(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final analytics = snapshot.data!;
              
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 600;
                  final maxWidth = isTablet ? 800.0 : double.infinity;
                  
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: AppTheme.spacing4,
                      right: AppTheme.spacing4,
                      top: AppTheme.spacing4,
                      bottom: AppTheme.spacing4 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverviewCards(context, analytics),
                          const SizedBox(height: AppTheme.spacing6),
                          _buildQuickStats(context, analytics),
                          const SizedBox(height: AppTheme.spacing6),
                          _buildDetailedAnalytics(context),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing4),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                context,
                'Total Decks',
                analytics.totalDecks.toString(),
                Icons.folder,
                AppTheme.blue600,
              ),
            ),
            const SizedBox(width: AppTheme.spacing2),
            Expanded(
              child: _buildOverviewCard(
                context,
                'Total Cards',
                analytics.totalFlashcards.toString(),
                Icons.style,
                AppTheme.bambooGreen600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing2),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                context,
                'Due Today',
                analytics.dueToday.toString(),
                Icons.assignment,
                AppTheme.amber600,
              ),
            ),
            const SizedBox(width: AppTheme.spacing2),
            Expanded(
              child: _buildOverviewCard(
                context,
                'Streak',
                '${analytics.currentStreak} days',
                Icons.local_fire_department,
                AppTheme.red600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Semantics(
      label: '$label: $value',
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.roundedSm),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Study Metrics',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing4),
        CustomCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatItem(
                      context,
                      'Cards Studied',
                      analytics.cardsStudiedToday.toString(),
                      Icons.check_circle,
                      AppTheme.bambooGreen600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  Expanded(
                    child: _buildQuickStatItem(
                      context,
                      'Avg Quiz Score',
                      '${analytics.averageQuizScore.toStringAsFixed(1)}%',
                      Icons.quiz,
                      AppTheme.purple600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing4),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatItem(
                      context,
                      'Total Study Time',
                      _formatMinutes(analytics.totalStudyMinutes),
                      Icons.access_time,
                      AppTheme.blue600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  Expanded(
                    child: _buildQuickStatItem(
                      context,
                      'Quiz Attempts',
                      analytics.quizAttempts.toString(),
                      Icons.emoji_events,
                      AppTheme.amber600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
        ),
        const SizedBox(height: AppTheme.spacing2),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing1),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedAnalytics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Analytics',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing4),
        _buildAnalyticsTile(
          context,
          'Daily Activity',
          'View your study activity over time',
          Icons.bar_chart,
          AppTheme.blue600,
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const DailyActivityChartScreen(),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing2),
        _buildAnalyticsTile(
          context,
          'Quiz Performance',
          'Track your quiz scores and progress',
          Icons.trending_up,
          AppTheme.bambooGreen600,
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const QuizPerformanceScreen(),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing2),
        _buildAnalyticsTile(
          context,
          'Mastery Breakdown',
          'See your card mastery distribution',
          Icons.pie_chart,
          AppTheme.amber600,
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MasteryBreakdownScreen(),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing2),
        _buildAnalyticsTile(
          context,
          'Weak Topics',
          'Identify areas that need improvement',
          Icons.warning,
          AppTheme.red600,
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const WeakTopicsScreen(),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing2),
        _buildAnalyticsTile(
          context,
          'Study Time',
          'View your study time statistics',
          Icons.access_time,
          AppTheme.purple600,
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const StudyTimeScreen(),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing2),
        _buildAnalyticsTile(
          context,
          'Subject Accuracy',
          'Compare accuracy across decks',
          Icons.track_changes,
          AppTheme.teal600,
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SubjectAccuracyScreen(),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing2),
        _buildAnalyticsTile(
          context,
          'Insights',
          'Get personalized study recommendations',
          Icons.lightbulb,
          AppTheme.amber500,
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const InsightsScreen(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  Widget _buildAnalyticsTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return CustomCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.roundedSm),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacing4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacing1),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}