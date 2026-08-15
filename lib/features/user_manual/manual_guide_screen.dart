import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import 'manual_content.dart';
import 'manual_widgets.dart';

/// Renders a single [ManualSection] with all its topics, quick-start
/// steps, best practices, and troubleshooting items.
///
/// On tablets in landscape, a sticky table of contents is shown on the
/// left and the content scrolls on the right.
class ManualGuideScreen extends StatelessWidget {
  final ManualSection section;

  const ManualGuideScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: section.title),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTabletLandscape =
                constraints.maxWidth >= 900 &&
                MediaQuery.of(context).orientation == Orientation.landscape;

            if (isTabletLandscape) {
              return _buildTabletLayout(context);
            }
            return _buildPhoneLayout(context);
          },
        ),
      ),
    );
  }

  // ── Phone / tablet portrait layout ───────────────────────────────────

  Widget _buildPhoneLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing6),
      children: _buildContent(context),
    );
  }

  // ── Tablet landscape layout with sticky TOC ──────────────────────────

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 280,
          child: _buildTableOfContents(context),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacing6),
            children: _buildContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTableOfContents(BuildContext context) {
    final tocItems = <_TocItem>[];
    if (section.intro != null) {
      tocItems.add(const _TocItem(id: 'intro', title: 'Overview'));
    }
    if (section.quickStartSteps.isNotEmpty) {
      tocItems.add(const _TocItem(id: 'quick-start', title: 'Quick Start'));
    }
    for (final topic in section.topics) {
      tocItems.add(_TocItem(id: 'topic-${topic.id}', title: topic.title));
    }
    if (section.bestPractices.isNotEmpty) {
      tocItems.add(const _TocItem(id: 'best-practices', title: 'Best Practices'));
    }
    if (section.troubleshooting.isNotEmpty) {
      tocItems.add(const _TocItem(id: 'troubleshooting', title: 'Troubleshooting'));
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contents', style: AppTheme.titleMedium),
          const SizedBox(height: AppTheme.spacing3),
          ...tocItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing2),
                child: Text(
                  item.title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ── Content builders ─────────────────────────────────────────────────

  List<Widget> _buildContent(BuildContext context) {
    final children = <Widget>[];

    children.add(ManualSectionHeader(
      title: section.title,
      subtitle: section.subtitle,
      icon: section.icon,
      iconColor: section.iconColor,
    ));

    if (section.intro != null) {
      children.add(const SizedBox(height: AppTheme.spacing4));
      children.add(ManualIntroCard(text: section.intro!));
    }

    if (section.quickStartSteps.isNotEmpty) {
      children.add(const SizedBox(height: AppTheme.spacing4));
      children.add(ManualQuickStartCard(
        steps: section.quickStartSteps,
        accentColor: section.iconColor,
      ));
    }

    if (section.topics.isNotEmpty) {
      children.add(const SizedBox(height: AppTheme.spacing6));
      children.add(Text('Guide', style: AppTheme.titleMedium));
      children.add(const SizedBox(height: AppTheme.spacing3));
      children.add(ManualResponsiveGrid(
        children: section.topics
            .map((topic) => ManualTopicCard(
                  topic: topic,
                  accentColor: section.iconColor,
                ))
            .toList(),
      ));
    }

    if (section.bestPractices.isNotEmpty) {
      children.add(const SizedBox(height: AppTheme.spacing4));
      children.add(ManualBestPracticesCard(
        practices: section.bestPractices,
        accentColor: section.iconColor,
      ));
    }

    if (section.troubleshooting.isNotEmpty) {
      children.add(const SizedBox(height: AppTheme.spacing6));
      children.add(Text('Troubleshooting', style: AppTheme.titleMedium));
      children.add(const SizedBox(height: AppTheme.spacing3));
      children.add(Column(
        children: List.generate(section.troubleshooting.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing3),
            child: ManualTroubleshootingCard(
              item: section.troubleshooting[i],
              index: i,
            ),
          );
        }),
      ));
    }

    children.add(const SizedBox(height: AppTheme.spacing6));

    return children;
  }
}

/// Simple data classes for the table of contents and deep links.
class _TocItem {
  final String id;
  final String title;
  const _TocItem({required this.id, required this.title});
}
