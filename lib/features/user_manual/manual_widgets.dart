import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_card.dart';
import 'manual_content.dart';

/// Reusable building blocks for the User Manual screens.

/// A section header with an icon badge, title, and subtitle.
class ManualSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const ManualSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(width: AppTheme.spacing4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
      ),
    );
  }
}

/// An intro paragraph card shown at the top of a guide screen.
class ManualIntroCard extends StatelessWidget {
  final String text;

  const ManualIntroCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: AppTheme.spacing3),
          Expanded(
            child: SelectableText(
              text,
              style: AppTheme.bodyMedium.copyWith(
                height: 1.5,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A topic card with an icon, title, subtitle, and expandable content.
class ManualTopicCard extends StatelessWidget {
  final ManualTopic topic;
  final Color accentColor;

  const ManualTopicCard({
    super.key,
    required this.topic,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing4,
          vertical: 0,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppTheme.spacing4,
          0,
          AppTheme.spacing4,
          AppTheme.spacing4,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(topic.icon, color: accentColor, size: 22),
        ),
        title: Text(topic.title, style: AppTheme.titleMedium),
        subtitle: Text(
          topic.subtitle,
          style: AppTheme.bodySmall.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6),
          ),
        ),
        children: [
          _buildTopicContent(context),
        ],
      ),
    );
  }

  Widget _buildTopicContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: AppTheme.spacing3),
        if (topic.bulletPoints.isNotEmpty) ...[
          _BulletList(items: topic.bulletPoints),
          const SizedBox(height: AppTheme.spacing3),
        ],
        if (topic.steps.isNotEmpty) ...[
          _StepList(steps: topic.steps, accentColor: accentColor),
          const SizedBox(height: AppTheme.spacing3),
        ],
        if (topic.infoTable.isNotEmpty) ...[
          _InfoTable(rows: topic.infoTable),
          const SizedBox(height: AppTheme.spacing3),
        ],
        if (topic.note != null) ...[
          _NoteCard(
            text: topic.note!,
            icon: Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppTheme.spacing3),
        ],
        if (topic.tip != null) ...[
          _NoteCard(
            text: topic.tip!,
            icon: Icons.lightbulb_outline,
            color: AppTheme.amber600,
          ),
        ],
      ],
    );
  }
}

/// A bullet point list with check-style icons.
class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Icon(
                  Icons.circle,
                  size: 6,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.spacing3),
              Expanded(
                child: SelectableText(
                  item,
                  style: AppTheme.bodyMedium.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// A numbered step list with circular badges.
class _StepList extends StatelessWidget {
  final List<ManualStep> steps;
  final Color accentColor;
  const _StepList({required this.steps, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Steps',
          style: AppTheme.labelLarge.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppTheme.spacing2),
        ...List.generate(steps.length, (index) {
          final step = steps[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: AppTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        step.description,
                        style: AppTheme.bodySmall.copyWith(
                          height: 1.4,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// A simple key-value info table.
class _InfoTable extends StatelessWidget {
  final List<ManualInfoRow> rows;
  const _InfoTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: rows.map((row) {
          final isEmpty = row.label.isEmpty && row.value.isEmpty;
          if (isEmpty) {
            return Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            );
          }
          final isHeader =
              row.label == 'Type' || row.label == 'Best for' ||
              row.label == 'Answer format' || row.label == 'Exam input';
          return Container(
            decoration: isHeader && row.label == 'Type'
                ? BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing3,
                vertical: AppTheme.spacing2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      row.label,
                      style: AppTheme.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      row.value,
                      style: AppTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A note/tip card with an icon and colored background.
class _NoteCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _NoteCard({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppTheme.spacing3),
          Expanded(
            child: SelectableText(
              text,
              style: AppTheme.bodySmall.copyWith(
                height: 1.4,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A quick-start steps card with numbered steps in a highlighted container.
class ManualQuickStartCard extends StatelessWidget {
  final List<ManualStep> steps;
  final Color accentColor;

  const ManualQuickStartCard({
    super.key,
    required this.steps,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch_outlined, color: accentColor, size: 22),
                const SizedBox(width: AppTheme.spacing3),
                Text('Quick Start', style: AppTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppTheme.spacing3),
            ...List.generate(steps.length, (index) {
              final step = steps[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step.title, style: AppTheme.labelLarge),
                          const SizedBox(height: 2),
                          SelectableText(
                            step.description,
                            style: AppTheme.bodySmall.copyWith(
                              height: 1.4,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// A best-practices tips card.
class ManualBestPracticesCard extends StatelessWidget {
  final List<String> practices;
  final Color accentColor;

  const ManualBestPracticesCard({
    super.key,
    required this.practices,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    color: accentColor, size: 22),
                const SizedBox(width: AppTheme.spacing3),
                Text('Best Practices', style: AppTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppTheme.spacing3),
            ...practices.map((practice) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: accentColor, size: 20),
                    const SizedBox(width: AppTheme.spacing3),
                    Expanded(
                      child: SelectableText(
                        practice,
                        style: AppTheme.bodyMedium.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// An expandable troubleshooting FAQ card.
class ManualTroubleshootingCard extends StatefulWidget {
  final ManualTroubleshootingItem item;
  final int index;

  const ManualTroubleshootingCard({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  State<ManualTroubleshootingCard> createState() =>
      _ManualTroubleshootingCardState();
}

class _ManualTroubleshootingCardState extends State<ManualTroubleshootingCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return CustomCard(
      child: ExpansionTile(
        key: ValueKey('troubleshoot-${widget.index}'),
        initiallyExpanded: _expanded,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing4,
          vertical: 0,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppTheme.spacing4,
          0,
          AppTheme.spacing4,
          AppTheme.spacing4,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: errorColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(
            Icons.help_outline,
            color: errorColor,
            size: 22,
          ),
        ),
        title: Text(
          widget.item.question,
          style: AppTheme.titleMedium,
        ),
        subtitle: Text(
          widget.item.symptom,
          maxLines: _expanded ? null : 2,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: AppTheme.bodySmall.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6),
          ),
        ),
        children: [
          const Divider(),
          const SizedBox(height: AppTheme.spacing3),
          _TroubleshootSection(
            label: 'Symptom',
            text: widget.item.symptom,
            icon: Icons.report_problem_outlined,
            color: errorColor,
          ),
          const SizedBox(height: AppTheme.spacing3),
          _TroubleshootSection(
            label: 'Cause',
            text: widget.item.cause,
            icon: Icons.search_outlined,
            color: AppTheme.amber600,
          ),
          const SizedBox(height: AppTheme.spacing3),
          _TroubleshootSection(
            label: 'Solution',
            text: widget.item.solution,
            icon: Icons.check_circle_outline,
            color: AppTheme.bambooGreen600,
          ),
        ],
      ),
    );
  }
}

class _TroubleshootSection extends StatelessWidget {
  final String label;
  final String text;
  final IconData icon;
  final Color color;
  const _TroubleshootSection({
    required this.label,
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: AppTheme.spacing2),
            Text(
              label,
              style: AppTheme.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing2),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: SelectableText(
            text,
            style: AppTheme.bodySmall.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }
}

/// A "deep link" button that navigates to a real app screen.
class ManualDeepLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const ManualDeepLinkButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing4,
              vertical: AppTheme.spacing3,
            ),
            child: Row(
              children: [
                Icon(icon, color: accent, size: 22),
                const SizedBox(width: AppTheme.spacing3),
                Expanded(
                  child: Text(
                    label,
                    style: AppTheme.labelLarge.copyWith(color: accent),
                  ),
                ),
                Icon(Icons.arrow_forward, color: accent, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A responsive grid that shows 1 column on phones and 2 on tablets.
class ManualResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const ManualResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = AppTheme.spacing4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        if (!isTablet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .map((child) => Padding(
                      padding: EdgeInsets.only(bottom: spacing),
                      child: child,
                    ))
                .toList(),
          );
        }
        // Two-column layout for tablets.
        final List<Widget> left = [];
        final List<Widget> right = [];
        for (int i = 0; i < children.length; i++) {
          (i.isEven ? left : right).add(Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: children[i],
          ));
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: left)),
            SizedBox(width: spacing),
            Expanded(child: Column(children: right)),
          ],
        );
      },
    );
  }
}

/// Highlights matching search terms in a text snippet.
class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? baseStyle;
  final TextStyle? highlightStyle;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.baseStyle,
    this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return SelectableText(text, style: baseStyle);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var remaining = text;
    var remainingLower = lowerText;

    while (remainingLower.contains(lowerQuery)) {
      final index = remainingLower.indexOf(lowerQuery);
      if (index > 0) {
        spans.add(TextSpan(
          text: remaining.substring(0, index),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: remaining.substring(index, index + query.length),
        style: highlightStyle ??
            baseStyle?.copyWith(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.2),
              fontWeight: FontWeight.bold,
            ),
      ));
      remaining = remaining.substring(index + query.length);
      remainingLower = remaining.toLowerCase();
    }
    if (remaining.isNotEmpty) {
      spans.add(TextSpan(text: remaining, style: baseStyle));
    }

    return RichText(text: TextSpan(children: spans));
  }
}
