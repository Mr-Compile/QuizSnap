import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/loading_skeleton.dart';

class SubjectAccuracyScreen extends StatefulWidget {
  const SubjectAccuracyScreen({super.key});

  @override
  State<SubjectAccuracyScreen> createState() => _SubjectAccuracyScreenState();
}

class _SubjectAccuracyScreenState extends State<SubjectAccuracyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Subject Accuracy',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: dbProvider.analyticsRepository.getAccuracyByDeck(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final deckAccuracies = snapshot.data!;
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverallAccuracy(context, deckAccuracies),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildAccuracyChart(context, deckAccuracies),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildDeckList(context, deckAccuracies),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOverallAccuracy(BuildContext context, deckAccuracies) {
    if (deckAccuracies.isEmpty) {
      return const SizedBox();
    }

    final overallAccuracy = deckAccuracies.isEmpty
        ? 0.0
        : deckAccuracies.fold<double>(
            0.0,
            (sum, deck) => sum + deck.accuracy,
          ) / deckAccuracies.length;

    final accuracyColor = overallAccuracy >= 80
        ? Colors.green
        : overallAccuracy >= 60
            ? Colors.orange
            : Colors.red;

    return CustomCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              color: accuracyColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              overallAccuracy >= 80 ? Icons.check_circle : Icons.trending_up,
              color: accuracyColor,
              size: 32,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Accuracy',
                  style: AppTheme.labelLarge,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  '${overallAccuracy.toStringAsFixed(1)}%',
                  style: AppTheme.headlineMedium.copyWith(
                    color: accuracyColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${deckAccuracies.length} decks',
            style: AppTheme.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyChart(BuildContext context, deckAccuracies) {
    if (deckAccuracies.isEmpty) {
      return CustomCard(
        child: Column(
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No decks available',
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
            'Accuracy by Deck',
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            height: 200.0 + (deckAccuracies.length * 30).toDouble(),
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
                      reservedSize: 100,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= deckAccuracies.length) return const SizedBox();
                        final deck = deckAccuracies[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                          child: Text(
                            deck.deckName.length > 10
                                ? '${deck.deckName.substring(0, 10)}...'
                                : deck.deckName,
                            style: AppTheme.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                barGroups: _createBarGroups(context, deckAccuracies),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups(BuildContext context, deckAccuracies) {
    if (deckAccuracies.isEmpty) {
      return [];
    }

    return deckAccuracies.asMap().entries.map((entry) {
      final accuracy = entry.value.accuracy.toDouble(); // Ensure double type
      final color = accuracy >= 80
          ? Colors.green
          : accuracy >= 60
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

  Widget _buildDeckList(BuildContext context, deckAccuracies) {
    if (deckAccuracies.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deck Details',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ...deckAccuracies.map((deck) => _buildDeckItem(context, deck)),
      ],
    );
  }

  Widget _buildDeckItem(BuildContext context, deck) {
    final accuracy = deck.accuracy;
    final accuracyColor = accuracy >= 80
        ? Colors.green
        : accuracy >= 60
            ? Colors.orange
            : Colors.red;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deck.deckName,
                  style: AppTheme.labelLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: accuracyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  '${accuracy.toStringAsFixed(1)}%',
                  style: AppTheme.labelSmall.copyWith(
                    color: accuracyColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: LinearProgressIndicator(
              value: accuracy / 100,
              backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(accuracyColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              Icon(
                Icons.style,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                '${deck.totalCards} cards',
                style: AppTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}