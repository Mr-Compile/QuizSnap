import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/repositories/analytics_repository.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/question_type_chip.dart';
import '../../core/utils/question_type_helper.dart';
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
        title: 'Dashboard',
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
                return EmptyState(
                  icon: Icons.error_outline,
                  title: 'Unable to load dashboard',
                  subtitle: 'Pull down to refresh or try again later',
                  action: TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                );
              }

              final analytics = snapshot.data!;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 600;
                  final maxWidth = isTablet ? 800.0 : double.infinity;

                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: AppTheme.spacing4,
                        right: AppTheme.spacing4,
                        top: AppTheme.spacing4,
                        bottom: AppTheme.spacing4 +
                            MediaQuery.of(context).padding.bottom,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGreetingHeader(context, analytics),
                            const SizedBox(height: AppTheme.spacing6),
                            _buildQuickActions(context),
                            const SizedBox(height: AppTheme.spacing6),
                            _buildStatisticsCards(context, analytics),
                            const SizedBox(height: AppTheme.spacing6),
                            _buildQuestionTypeBreakdown(context, dbProvider),
                            const SizedBox(height: AppTheme.spacing6),
                            _buildChartsSection(context),
                          ],
                        ),
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

  // ─────────────────────────────────────────────────────────────────────
  //  Greeting header — greeting, study streak, today's study time, cards
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildGreetingHeader(BuildContext context, analytics) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.spacing1),
        Text(
          'Ready to continue your study journey?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Row(
          children: [
            Expanded(
              child: _buildHighlightChip(
                context,
                icon: Icons.local_fire_department,
                value: '${analytics.currentStreak}',
                label: 'day streak',
                color: AppTheme.red600,
              ),
            ),
            const SizedBox(width: AppTheme.spacing2),
            Expanded(
              child: _buildHighlightChip(
                context,
                icon: Icons.access_time,
                value: AppTheme.formatStudyDuration(analytics.totalStudySeconds),
                label: 'study time',
                color: AppTheme.blue600,
              ),
            ),
            const SizedBox(width: AppTheme.spacing2),
            Expanded(
              child: _buildHighlightChip(
                context,
                icon: Icons.check_circle,
                value: '${analytics.cardsStudiedToday}',
                label: 'cards today',
                color: AppTheme.bambooGreen600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightChip(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Semantics(
      label: '$value $label',
      child: CustomCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing2,
            vertical: AppTheme.spacing2,
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: AppTheme.spacing1),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Quick actions — Continue Study, Start Exam, Review Bookmarks, AI
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.spacing3),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 600 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.1,
              mainAxisSpacing: AppTheme.spacing2,
              crossAxisSpacing: AppTheme.spacing2,
              children: [
                _buildQuickAction(
                  context,
                  icon: Icons.play_circle_fill,
                  label: 'Continue\nStudy',
                  color: AppTheme.bambooGreen600,
                  onTap: () => GoRouter.of(context).push(AppRoutes.studyHome),
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.quiz,
                  label: 'Start\nExam',
                  color: AppTheme.purple600,
                  onTap: () => GoRouter.of(context).push(AppRoutes.studyHome),
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.bookmark,
                  label: 'Review\nBookmarks',
                  color: AppTheme.amber600,
                  onTap: () =>
                      GoRouter.of(context).push(AppRoutes.bookmarks),
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.auto_awesome,
                  label: 'AI\nGenerate',
                  color: AppTheme.blue600,
                  onTap: () =>
                      GoRouter.of(context).push(AppRoutes.aiGenerate),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label.replaceAll('\n', ' '),
      child: CustomCard(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: AppTheme.spacing2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Statistics cards — Total Decks, Flashcards, Accuracy, Study Time
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStatisticsCards(BuildContext context, analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.spacing3),
        LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            if (isTablet) {
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Decks',
                      analytics.totalDecks.toString(),
                      Icons.folder_outlined,
                      AppTheme.blue600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing2),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Flashcards',
                      analytics.totalFlashcards.toString(),
                      Icons.style_outlined,
                      AppTheme.bambooGreen600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing2),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Accuracy',
                      '${analytics.averageQuizScore.toStringAsFixed(1)}%',
                      Icons.gps_fixed,
                      AppTheme.purple600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing2),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Due Today',
                      analytics.dueToday.toString(),
                      Icons.assignment_outlined,
                      AppTheme.amber600,
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total Decks',
                        analytics.totalDecks.toString(),
                        Icons.folder_outlined,
                        AppTheme.blue600,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing2),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Flashcards',
                        analytics.totalFlashcards.toString(),
                        Icons.style_outlined,
                        AppTheme.bambooGreen600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing2),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Accuracy',
                        '${analytics.averageQuizScore.toStringAsFixed(1)}%',
                        Icons.gps_fixed,
                        AppTheme.purple600,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing2),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Due Today',
                        analytics.dueToday.toString(),
                        Icons.assignment_outlined,
                        AppTheme.amber600,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Semantics(
      label: '$label: $value',
      child: CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing3),
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
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Question-type breakdown — counts, reviews, accuracy per type
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildQuestionTypeBreakdown(
      BuildContext context, DatabaseProvider dbProvider) {
    return FutureBuilder<List<QuestionTypeStats>>(
      future: dbProvider.analyticsRepository.getQuestionTypeStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError || !snapshot.hasData) return const SizedBox.shrink();

        final stats = snapshot.data!;
        final totalCards =
            stats.fold<int>(0, (sum, s) => sum + s.totalCount);
        if (totalCards == 0) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By Question Type', style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spacing3),
            ...stats.map((s) => _buildTypeStatRow(context, s, totalCards)),
          ],
        );
      },
    );
  }

  Widget _buildTypeStatRow(
      BuildContext context, QuestionTypeStats stats, int totalCards) {
    final percentage =
        totalCards > 0 ? (stats.totalCount / totalCards) * 100 : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing3),
      child: CustomCard(
        child: Row(
          children: [
            QuestionTypeChip(questionType: stats.questionType),
            const SizedBox(width: AppTheme.spacing4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stats.totalCount} cards  •  ${stats.totalReviews} reviews',
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.spacing1),
                  Text(
                    stats.totalReviews > 0
                        ? 'Accuracy: ${stats.accuracy.toStringAsFixed(1)}%'
                        : 'No reviews yet',
                    style: AppTheme.bodySmall.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 6,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _typeColor(stats.questionType),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case QuestionTypeHelper.multipleChoice:
        return AppTheme.purple600;
      case QuestionTypeHelper.enumeration:
        return AppTheme.orange600;
      default:
        return AppTheme.blue600;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Charts section — Daily Activity, Weekly Study Time, Accuracy Trend
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildChartsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Charts & Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.spacing3),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacing1),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
