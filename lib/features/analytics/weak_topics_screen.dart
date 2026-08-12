import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/database_provider.dart';
import '../../core/models/analytics_data.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/loading_skeleton.dart';

class WeakTopicsScreen extends StatefulWidget {
  const WeakTopicsScreen({super.key});

  @override
  State<WeakTopicsScreen> createState() => _WeakTopicsScreenState();
}

class _WeakTopicsScreenState extends State<WeakTopicsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Weak Topics',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder<List<WeakTopicChartItem>>(
            future: dbProvider.analyticsRepository.getWeakTopicChartItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final allItems = snapshot.data ?? <WeakTopicChartItem>[];
              final weakTopics =
                  allItems.where((d) => d.isWeak).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (weakTopics.isEmpty)
                      _buildNoWeakTopics(context)
                    else
                      _buildWeakTopicsList(context, weakTopics),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildAllTopicsChart(context, allItems),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildRecommendations(context, weakTopics),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoWeakTopics(BuildContext context) {
    return CustomCard(
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: Colors.green,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Great job!',
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'All your decks are performing well. Keep up the good work!',
            style: AppTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeakTopicsList(
      BuildContext context, List<WeakTopicChartItem> weakTopics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topics Needing Attention',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ...weakTopics.map((topic) => _buildWeakTopicItem(context, topic)),
      ],
    );
  }

  Widget _buildWeakTopicItem(BuildContext context, WeakTopicChartItem topic) {
    final accuracy = topic.accuracy;
    final accuracyColor = accuracy >= 60.0 ? Colors.orange : Colors.red;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: accuracyColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  topic.name,
                  style: AppTheme.labelLarge,
                ),
              ),
              Text(
                '${accuracy.toStringAsFixed(1)}%',
                style: AppTheme.labelLarge.copyWith(
                  color: accuracyColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: LinearProgressIndicator(
              value: accuracy / 100.0,
              backgroundColor:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(accuracyColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '${topic.cardCount} cards',
            style: AppTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTopicsChart(
      BuildContext context, List<WeakTopicChartItem> items) {
    if (items.isEmpty) {
      return const SizedBox();
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Topics Performance',
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            height: 200.0 + (items.length * 30).toDouble(),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 100,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= items.length) {
                          return const SizedBox();
                        }
                        final deck = items[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                          child: Text(
                            deck.name.length > 10
                                ? '${deck.name.substring(0, 10)}...'
                                : deck.name,
                            style: AppTheme.bodySmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: AppTheme.bodySmall.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: _createBarGroups(context, items),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups(
      BuildContext context, List<WeakTopicChartItem> items) {
    if (items.isEmpty) {
      return <BarChartGroupData>[];
    }

    return items.asMap().entries.map((entry) {
      final accuracy = entry.value.accuracy.toDouble();
      final color = accuracy >= 80.0
          ? Colors.green
          : accuracy >= 60.0
              ? Colors.orange
              : Colors.red;

      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: accuracy,
            color: color,
            width: 16,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildRecommendations(
      BuildContext context, List<WeakTopicChartItem> weakTopics) {
    if (weakTopics.isEmpty) {
      return const SizedBox();
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Colors.amber,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Recommendations',
                style: AppTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildRecommendationItem(
            context,
            'Focus on weak topics',
            'Prioritize studying decks with lower accuracy scores to improve overall performance.',
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildRecommendationItem(
            context,
            'Use spaced repetition',
            'Review cards from weak topics more frequently to reinforce learning.',
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildRecommendationItem(
            context,
            'Create focused sessions',
            'Dedicate study sessions specifically to your weakest topics.',
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    BuildContext context,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.arrow_right,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.labelLarge,
              ),
              Text(
                description,
                style: AppTheme.bodySmall.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
