import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/loading_skeleton.dart';

class MasteryBreakdownScreen extends StatefulWidget {
  const MasteryBreakdownScreen({super.key});

  @override
  State<MasteryBreakdownScreen> createState() => _MasteryBreakdownScreenState();
}

class _MasteryBreakdownScreenState extends State<MasteryBreakdownScreen> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mastery Breakdown',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: dbProvider.analyticsRepository.getMasteryDistribution(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final distribution = snapshot.data!;
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPieChart(context, distribution),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildMasteryDetails(context, distribution),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildMasteryInfo(context),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, distribution) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card Mastery Distribution',
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse
                          .touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: _createPieSections(context, distribution),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _createPieSections(BuildContext context, List<dynamic> distribution) {
    final colors = [
      Theme.of(context).colorScheme.primary, // Mastered
      Theme.of(context).colorScheme.tertiary, // Learning
      Theme.of(context).colorScheme.secondary, // New
    ];

    return distribution.asMap().entries.map((entry) {
      final isTouched = entry.key == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;

      final value = entry.value.count.toDouble();
      final percentage = entry.value.percentage;

      return PieChartSectionData(
        color: colors[entry.key],
        value: value > 0 ? value : 0.1, // Minimum value to show section
        title: percentage > 0 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      );
    }).toList();
  }

  Widget _buildMasteryDetails(BuildContext context, distribution) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mastery Levels',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ...distribution.map((item) => _buildMasteryItem(context, item)),
      ],
    );
  }

  Widget _buildMasteryItem(BuildContext context, item) {
    final color = item.level == 'Mastered'
        ? Theme.of(context).colorScheme.primary
        : item.level == 'Learning'
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.secondary;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.level,
                  style: AppTheme.labelLarge,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  '${item.count} cards',
                  style: AppTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.percentage.toStringAsFixed(1)}%',
            style: AppTheme.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryInfo(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Mastery Levels',
                style: AppTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildInfoItem(
            context,
            'Mastered',
            'Cards with review interval > 21 days',
            Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildInfoItem(
            context,
            'Learning',
            'Cards with review interval 1-21 days',
            Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildInfoItem(
            context,
            'New',
            'Cards that haven\'t been reviewed yet',
            Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}