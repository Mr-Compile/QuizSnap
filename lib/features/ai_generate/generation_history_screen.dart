import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/recent_generation.dart';
import '../../core/repositories/recent_generation_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import 'recent_generation_details_screen.dart';

/// Full scrollable history of all AI generations, grouped by date.
///
/// Reached via "View All" from the compact Recent Generations preview on the
/// AI Generate home screen.
class GenerationHistoryScreen extends StatelessWidget {
  const GenerationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Generation History'),
      body: Consumer<RecentGenerationRepository>(
        builder: (context, repo, _) {
          final generations = repo.generations;
          if (generations.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'No generations yet',
              subtitle: 'Your generated questions will appear here',
            );
          }

          final groups = _groupByDate(generations);
          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _DateGroupSection(
                label: group.label,
                items: group.items,
              );
            },
          );
        },
      ),
    );
  }

  List<_DateGroup> _groupByDate(List<RecentGeneration> generations) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <RecentGeneration>[];
    final yesterdayItems = <RecentGeneration>[];
    final earlierItems = <RecentGeneration>[];

    for (final gen in generations) {
      final genDate = DateTime(
        gen.generatedAt.year,
        gen.generatedAt.month,
        gen.generatedAt.day,
      );
      if (genDate == today) {
        todayItems.add(gen);
      } else if (genDate == yesterday) {
        yesterdayItems.add(gen);
      } else {
        earlierItems.add(gen);
      }
    }

    final groups = <_DateGroup>[];
    if (todayItems.isNotEmpty) {
      groups.add(_DateGroup(label: 'Today', items: todayItems));
    }
    if (yesterdayItems.isNotEmpty) {
      groups.add(_DateGroup(label: 'Yesterday', items: yesterdayItems));
    }
    if (earlierItems.isNotEmpty) {
      groups.add(_DateGroup(label: 'Earlier', items: earlierItems));
    }
    return groups;
  }
}

class _DateGroup {
  final String label;
  final List<RecentGeneration> items;
  _DateGroup({required this.label, required this.items});
}

class _DateGroupSection extends StatelessWidget {
  final String label;
  final List<RecentGeneration> items;

  const _DateGroupSection({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: label == 'Today' ? 0 : AppTheme.spacingMd,
            bottom: AppTheme.spacingSm,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ),
        ...items.map((gen) => _GenerationHistoryItem(generation: gen)),
      ],
    );
  }
}

class _GenerationHistoryItem extends StatelessWidget {
  final RecentGeneration generation;

  const _GenerationHistoryItem({required this.generation});

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat.jm().format(generation.generatedAt);

    return CustomCard(
      onTap: () => _openDetails(context),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  generation.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${generation.questionCount} questions • ${generation.savedDeckId != null ? 'Saved' : 'Unsaved'} • $formattedTime',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
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

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            RecentGenerationDetailsScreen(generation: generation),
      ),
    );
  }
}
