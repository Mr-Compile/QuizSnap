import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing4),
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
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppTheme.spacing2),
            Expanded(
              child: _buildOverviewCard(
                context,
                'Total Cards',
                analytics.totalFlashcards.toString(),
                Icons.style,
                Colors.green,
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
                Colors.orange,
              ),
            ),
            const SizedBox(width: AppTheme.spacing2),
            Expanded(
              child: _buildOverviewCard(
                context,
                'Streak',
                '${analytics.currentStreak} days',
                Icons.local_fire_department,
                Colors.red,
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
    return CustomCard(
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
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildQuickStats(BuildContext context, analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Progress',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing4),
        CustomCard(
          child: Row(
            children: [
              Expanded(
                child: _buildQuickStatItem(
                  context,
                  'Cards Studied',
                  analytics.cardsStudiedToday.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: AppTheme.spacing4),
              Expanded(
                child: _buildQuickStatItem(
                  context,
                  'Avg Quiz Score',
                  '${analytics.averageQuizScore.toStringAsFixed(1)}%',
                  Icons.quiz,
                  Colors.purple,
                ),
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
          Colors.blue,
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
          Colors.green,
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
          Colors.orange,
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
          Colors.red,
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
          Colors.purple,
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
          Colors.teal,
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
          Colors.amber,
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const InsightsScreen(),
            ),
          ),
        ),
      ],
    );
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
                ),
                const SizedBox(height: AppTheme.spacing1),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
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