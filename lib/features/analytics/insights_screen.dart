import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/loading_skeleton.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Insights',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: Future.wait([
              dbProvider.analyticsRepository.getAnalyticsSummary(),
              dbProvider.analyticsRepository.getAccuracyByDeck(),
              dbProvider.analyticsRepository.getMasteryDistribution(),
              dbProvider.analyticsRepository.getImprovementTrends(),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final summary = snapshot.data![0];
              final deckAccuracies = snapshot.data![1] as Map<String, double>;
              final masteryDistribution = snapshot.data![2] as Map<String, int>;
              final trends = snapshot.data![3] as Map<String, List<double>>;

              final insights = _generateInsights(summary, deckAccuracies, masteryDistribution, trends);
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInsightHeader(context, trends),
                    const SizedBox(height: AppTheme.spacingLg),
                    ...insights.map((insight) => _buildInsightCard(context, insight)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInsightHeader(BuildContext context, trends) {
    final trendColor = trends.trend == 'improving'
        ? Colors.green
        : trends.trend == 'declining'
            ? Colors.red
            : Colors.orange;

    final trendIcon = trends.trend == 'improving'
        ? Icons.trending_up
        : trends.trend == 'declining'
            ? Icons.trending_down
            : Icons.trending_flat;

    return CustomCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              trendIcon,
              color: trendColor,
              size: 32,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Trend',
                  style: AppTheme.labelLarge,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  trends.trend.toUpperCase(),
                  style: AppTheme.headlineSmall.copyWith(
                    color: trendColor,
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

  List<StudyInsight> _generateInsights(
    dynamic summary,
    Map<String, double> deckAccuracies,
    Map<String, int> masteryDistribution,
    Map<String, List<double>> trends,
  ) {
    final insights = <StudyInsight>[];

    // Due cards insight
    final dueToday = summary['dueToday'] as int? ?? 0;
    if (dueToday > 20) {
      insights.add(StudyInsight(
        type: InsightType.warning,
        title: 'High Card Load',
        description: 'You have $dueToday cards due today. Consider breaking this into multiple study sessions.',
        icon: Icons.warning,
        priority: InsightPriority.high,
      ));
    } else if (dueToday > 0) {
      insights.add(StudyInsight(
        type: InsightType.info,
        title: 'Cards Due Today',
        description: 'You have $dueToday cards due for review. Complete them to maintain your progress.',
        icon: Icons.assignment,
        priority: InsightPriority.medium,
      ));
    }

    // Streak insight
    final currentStreak = summary['currentStreak'] as int? ?? 0;
    if (currentStreak >= 7) {
      insights.add(StudyInsight(
        type: InsightType.achievement,
        title: 'Great Streak!',
        description: 'You\'ve studied for $currentStreak consecutive days. Keep it up!',
        icon: Icons.local_fire_department,
        priority: InsightPriority.low,
      ));
    } else if (currentStreak == 0) {
      insights.add(StudyInsight(
        type: InsightType.suggestion,
        title: 'Start a Streak',
        description: 'Study today to start building your learning streak. Consistency is key!',
        icon: Icons.local_fire_department_outlined,
        priority: InsightPriority.medium,
      ));
    }

    // Weak topics insight
    final weakTopics = deckAccuracies.entries.where((e) => e.value < 70).toList();
    if (weakTopics.isNotEmpty) {
      insights.add(StudyInsight(
        type: InsightType.suggestion,
        title: 'Focus on Weak Areas',
        description: 'You have ${weakTopics.length} deck(s) with accuracy below 70%. Prioritize these in your study sessions.',
        icon: Icons.flag,
        priority: InsightPriority.high,
      ));
    }

    // Mastery insight
    final newCardsCount = masteryDistribution['New'] ?? 0;
    if (newCardsCount > 20) {
      insights.add(StudyInsight(
        type: InsightType.info,
        title: 'Many New Cards',
        description: 'You have $newCardsCount new cards to learn. Start reviewing them to build your mastery.',
        icon: Icons.new_releases,
        priority: InsightPriority.medium,
      ));
    }

    // Trend insight - simplified for now since trends is a Map
    if (trends.isNotEmpty) {
      final accuracyValues = trends['accuracy'] ?? [];
      if (accuracyValues.length >= 2) {
        final recent = accuracyValues.last;
        final previous = accuracyValues[accuracyValues.length - 2];
        if (recent < previous - 10) {
          insights.add(StudyInsight(
            type: InsightType.warning,
            title: 'Performance Declining',
            description: 'Your accuracy has been decreasing recently. Consider reviewing fundamentals.',
            icon: Icons.trending_down,
            priority: InsightPriority.high,
          ));
        } else if (recent > previous + 10) {
          insights.add(StudyInsight(
            type: InsightType.achievement,
            title: 'Improving Performance',
            description: 'Your accuracy has been improving recently. Keep up the great work!',
            icon: Icons.trending_up,
            priority: InsightPriority.low,
          ));
        }
      }
    }

    // Study time insight - simplified
    final studyTimeValues = trends['studyTime'] ?? [];
    if (studyTimeValues.isNotEmpty) {
      final totalStudyTime = studyTimeValues.reduce((a, b) => a + b);
      if (totalStudyTime < 60) {
        insights.add(StudyInsight(
          type: InsightType.suggestion,
          title: 'Increase Study Time',
          description: 'You\'ve studied for ${totalStudyTime.toInt()} minutes recently. Try to study more consistently.',
          icon: Icons.access_time,
          priority: InsightPriority.medium,
        ));
      }
    }

    // Sort by priority
    insights.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    return insights;
  }

  Widget _buildInsightCard(BuildContext context, StudyInsight insight) {
    final color = _getInsightColor(insight.type);

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              insight.icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      insight.title,
                      style: AppTheme.labelLarge,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    _buildPriorityBadge(context, insight.priority),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  insight.description,
                  style: AppTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(BuildContext context, InsightPriority priority) {
    final color = priority == InsightPriority.high
        ? Colors.red
        : priority == InsightPriority.medium
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: AppTheme.labelSmall.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.achievement:
        return Colors.green;
      case InsightType.warning:
        return Colors.red;
      case InsightType.suggestion:
        return Colors.blue;
      case InsightType.info:
        return Colors.orange;
    }
  }
}

class StudyInsight {
  final InsightType type;
  final String title;
  final String description;
  final IconData icon;
  final InsightPriority priority;

  StudyInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.priority,
  });
}

enum InsightType {
  achievement,
  warning,
  suggestion,
  info,
}

enum InsightPriority {
  high,
  medium,
  low,
}