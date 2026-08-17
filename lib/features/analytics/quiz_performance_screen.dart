import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/loading_skeleton.dart';

class QuizPerformanceScreen extends StatefulWidget {
  const QuizPerformanceScreen({super.key});

  @override
  State<QuizPerformanceScreen> createState() => _QuizPerformanceScreenState();
}

class _QuizPerformanceScreenState extends State<QuizPerformanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Quiz Performance',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: Future.wait([
              dbProvider.analyticsRepository.getRecentQuizResults(limit: 20),
              dbProvider.analyticsRepository.getAnalyticsSummary(),
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

              final results = snapshot.data![0] as List;
              final summary = snapshot.data![1];
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPerformanceOverview(context, summary, results),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildScoreChart(context, results),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildRecentResults(context, results),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPerformanceOverview(BuildContext context, summary, List results) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  context,
                  'Average Score',
                  '${summary.averageQuizScore.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: _buildOverviewItem(
                  context,
                  'Total Quizzes',
                  '${results.length}',
                  Icons.quiz,
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(
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

  Widget _buildScoreChart(BuildContext context, List results) {
    if (results.isEmpty) {
      return CustomCard(
        child: Column(
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No quiz results yet',
              style: AppTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
          Text(
            'Score Trend',
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
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
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
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
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _createScoreSpots(results),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                        Theme.of(context).colorScheme.primary,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Theme.of(context).colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Theme.of(context).colorScheme.surface,
                        );
                      },
                    ),
                  ),
                ],
                minX: 0,
                maxX: (results.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _createScoreSpots(List results) {
    return results
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              (entry.value.score * 100).toDouble(),
            ))
        .toList();
  }

  Widget _buildRecentResults(BuildContext context, List results) {
    if (results.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Results',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ...results.take(5).map((result) => _buildResultItem(context, result)),
      ],
    );
  }

  Widget _buildResultItem(BuildContext context, result) {
    final score = (result.score * 100).toInt();
    final scoreColor = score >= 80
        ? Theme.of(context).colorScheme.primary
        : score >= 60
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.error;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              '$score%',
              style: AppTheme.labelLarge.copyWith(
                color: scoreColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.correctAnswers}/${result.totalQuestions} correct',
                  style: AppTheme.labelLarge,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  '${result.durationSeconds ~/ 60} min',
                  style: AppTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            result.quizType,
            style: AppTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}