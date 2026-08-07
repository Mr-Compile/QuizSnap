import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/loading_skeleton.dart';

class StudyTimeScreen extends StatefulWidget {
  const StudyTimeScreen({super.key});

  @override
  State<StudyTimeScreen> createState() => _StudyTimeScreenState();
}

class _StudyTimeScreenState extends State<StudyTimeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Study Time',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: dbProvider.analyticsRepository.getStudyTimeStats(),
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
                    _buildTimeOverview(context, stats),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildTimeChart(context, stats),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildSessionStats(context, stats),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimeOverview(BuildContext context, stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Study Time Overview',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: _buildTimeCard(
                context,
                'Today',
                stats.todayMinutes,
                stats.todaySessions,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildTimeCard(
                context,
                'This Week',
                stats.weekMinutes,
                stats.weekSessions,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Row(
          children: [
            Expanded(
              child: _buildTimeCard(
                context,
                'This Month',
                stats.monthMinutes,
                stats.monthSessions,
                Colors.purple,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildGoalCard(context, stats),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeCard(
    BuildContext context,
    String period,
    int minutes,
    int sessions,
    Color color,
  ) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final timeText = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return CustomCard(
      child: Column(
        children: [
          Icon(
            Icons.access_time,
            color: color,
            size: 32,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            timeText,
            style: AppTheme.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            period,
            style: AppTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '$sessions sessions',
            style: AppTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, stats) {
    // Assume daily goal of 30 minutes
    const dailyGoalMinutes = 30;
    final progress = (stats.todayMinutes / dailyGoalMinutes).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return CustomCard(
      child: Column(
        children: [
          Icon(
            Icons.flag,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '$percentage%',
            style: AppTheme.headlineSmall.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Daily Goal',
            style: AppTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChart(BuildContext context, stats) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Distribution',
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: stats.todayMinutes > stats.weekMinutes / 7
                    ? (stats.todayMinutes * 1.2).ceilToDouble()
                    : (stats.weekMinutes / 7 * 1.2).ceilToDouble(),
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
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
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = ['Today', 'Week Avg', 'Month Avg'];
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) return const SizedBox();
                        return Text(
                          labels[index],
                          style: AppTheme.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}m',
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
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: stats.todayMinutes.toDouble(),
                        color: Colors.blue,
                        width: 20,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: (stats.weekMinutes / 7).toDouble(),
                        color: Colors.green,
                        width: 20,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: (stats.monthMinutes / 30).toDouble(),
                        color: Colors.purple,
                        width: 20,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStats(BuildContext context, stats) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Statistics',
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildStatRow(
            context,
            'Today\'s Sessions',
            stats.todaySessions.toString(),
            Icons.event,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildStatRow(
            context,
            'Weekly Sessions',
            stats.weekSessions.toString(),
            Icons.date_range,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildStatRow(
            context,
            'Monthly Sessions',
            stats.monthSessions.toString(),
            Icons.calendar_month,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildStatRow(
            context,
            'Avg Session Duration',
            stats.todaySessions > 0
                ? '${(stats.todayMinutes / stats.todaySessions).toInt()} min'
                : '0 min',
            Icons.timer,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}