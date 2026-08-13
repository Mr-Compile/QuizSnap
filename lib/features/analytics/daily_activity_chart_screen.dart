import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/custom_card.dart';

class DailyActivityChartScreen extends StatefulWidget {
  const DailyActivityChartScreen({super.key});

  @override
  State<DailyActivityChartScreen> createState() => _DailyActivityChartScreenState();
}

class _DailyActivityChartScreenState extends State<DailyActivityChartScreen> {
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Daily Activity',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: dbProvider.analyticsRepository.getDailyStudyActivity(days: _selectedDays),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final activities = snapshot.data!;
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(context),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildActivityChart(context, activities),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildActivityStats(context, activities),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Row(
      children: [
        _buildPeriodChip(context, '7 Days', 7),
        const SizedBox(width: AppTheme.spacingSm),
        _buildPeriodChip(context, '30 Days', 30),
        const SizedBox(width: AppTheme.spacingSm),
        _buildPeriodChip(context, '90 Days', 90),
      ],
    );
  }

  Widget _buildPeriodChip(BuildContext context, String label, int days) {
    final isSelected = _selectedDays == days;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDays = days;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildActivityChart(BuildContext context, List activities) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cards Studied',
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
                  horizontalInterval: _calculateMaxY(activities) / 5,
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
                      reservedSize: 30,
                      interval: (_selectedDays ~/ 7).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= activities.length) return const SizedBox();
                        final activity = activities[index];
                        final date = DateFormat('MM/dd').format(activity.date);
                        return Text(
                          date,
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
                      interval: _calculateMaxY(activities) / 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
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
                    spots: _createSpots(activities),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                        Theme.of(context).colorScheme.primary,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minX: 0,
                maxX: (activities.length - 1).toDouble(),
                minY: 0,
                maxY: _calculateMaxY(activities),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _createSpots(List activities) {
    return activities
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              entry.value.cardsStudied.toDouble(),
            ))
        .toList();
  }

  double _calculateMaxY(List activities) {
    final maxCards = activities.fold<int>(
      0,
      (max, activity) => activity.cardsStudied > max ? activity.cardsStudied : max,
    );
    return maxCards > 0 ? (maxCards * 1.2).ceilToDouble() : 10;
  }

  Widget _buildActivityStats(BuildContext context, List activities) {
    final totalCards = activities.fold<int>(
      0,
      (sum, activity) => sum + (activity.cardsStudied as int),
    );
    final totalSeconds = activities.fold<int>(
      0,
      (sum, activity) => sum + (activity.studyTimeSeconds as int),
    );
    final avgAccuracy = activities.isEmpty
        ? 0.0
        : activities.fold<double>(
              0,
              (sum, activity) => sum + activity.accuracy,
            ) /
            activities.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total Cards Studied',
                totalCards.toString(),
                Icons.style,
                Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildStatCard(
                context,
                'Total Study Time',
                AppTheme.formatStudyDuration(totalSeconds),
                Icons.access_time,
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Average Accuracy',
                '${avgAccuracy.toStringAsFixed(1)}%',
                Icons.check_circle,
                Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildStatCard(
                context,
                'Active Days',
                activities.where((a) => a.cardsStudied > 0).length.toString(),
                Icons.calendar_today,
                Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
    return CustomCard(
      child: Column(
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}