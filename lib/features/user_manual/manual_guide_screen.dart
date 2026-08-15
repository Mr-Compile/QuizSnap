import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
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

    // Contextual deep links based on the section.
    children.add(const SizedBox(height: AppTheme.spacing6));
    children.add(_buildContextualDeepLinks(context));

    children.add(const SizedBox(height: AppTheme.spacing6));

    return children;
  }

  /// Returns section-specific deep-link buttons that navigate to the
  /// real app screen related to this guide section.
  Widget _buildContextualDeepLinks(BuildContext context) {
    final links = <_DeepLink>[];

    switch (section.id) {
      case 'getting-started':
        links.addAll([
          _DeepLink(
            label: 'Go to Library',
            icon: Icons.library_books_outlined,
            color: AppTheme.blue600,
            onTap: () => GoRouter.of(context).go(AppRoutes.decks),
          ),
          _DeepLink(
            label: 'Go to Study',
            icon: Icons.school_outlined,
            color: AppTheme.emerald600,
            onTap: () => GoRouter.of(context).go(AppRoutes.study),
          ),
        ]);
        break;
      case 'library':
        links.add(_DeepLink(
          label: 'Open Library',
          icon: Icons.library_books_outlined,
          color: AppTheme.blue600,
          onTap: () => GoRouter.of(context).go(AppRoutes.decks),
        ));
        links.add(_DeepLink(
          label: 'Open Trash',
          icon: Icons.delete_outline,
          color: AppTheme.orange600,
          onTap: () => GoRouter.of(context).push(AppRoutes.trash),
        ));
        break;
      case 'flashcards':
        links.add(_DeepLink(
          label: 'Open Library (create flashcards)',
          icon: Icons.library_books_outlined,
          color: AppTheme.purple600,
          onTap: () => GoRouter.of(context).go(AppRoutes.decks),
        ));
        break;
      case 'study-mode':
        links.add(_DeepLink(
          label: 'Open Study',
          icon: Icons.school_outlined,
          color: AppTheme.emerald600,
          onTap: () => GoRouter.of(context).go(AppRoutes.study),
        ));
        links.add(_DeepLink(
          label: 'Open Bookmarks',
          icon: Icons.bookmark_border_outlined,
          color: AppTheme.amber600,
          onTap: () => GoRouter.of(context).push(AppRoutes.bookmarks),
        ));
        break;
      case 'exam-mode':
        links.add(_DeepLink(
          label: 'Open Library (start an exam)',
          icon: Icons.quiz_outlined,
          color: AppTheme.amber600,
          onTap: () => GoRouter.of(context).go(AppRoutes.decks),
        ));
        break;
      case 'ai-generate':
        links.add(_DeepLink(
          label: 'Open AI Generate',
          icon: Icons.auto_awesome_outlined,
          color: AppTheme.purple600,
          onTap: () => GoRouter.of(context).go(AppRoutes.aiGenerate),
        ));
        links.add(_DeepLink(
          label: 'API Configuration',
          icon: Icons.api,
          color: AppTheme.purple600,
          onTap: () => GoRouter.of(context).push(AppRoutes.apiConfiguration),
        ));
        links.add(_DeepLink(
          label: 'AI Usage & Quota',
          icon: Icons.data_usage_outlined,
          color: AppTheme.purple600,
          onTap: () => GoRouter.of(context).push(AppRoutes.aiUsage),
        ));
        break;
      case 'backup-restore':
        links.add(_DeepLink(
          label: 'Open Backup & Restore',
          icon: Icons.backup_outlined,
          color: AppTheme.blue600,
          onTap: () => GoRouter.of(context)
              .push(AppRoutes.backupRestoreEnhanced),
        ));
        links.add(_DeepLink(
          label: 'Backup History',
          icon: Icons.history_outlined,
          color: AppTheme.blue600,
          onTap: () => GoRouter.of(context).push(AppRoutes.backupHistory),
        ));
        break;
      case 'security':
        links.add(_DeepLink(
          label: 'Open Security Settings',
          icon: Icons.security_outlined,
          color: AppTheme.red600,
          onTap: () => GoRouter.of(context).push(AppRoutes.security),
        ));
        break;
      case 'analytics':
        links.add(_DeepLink(
          label: 'Open Dashboard',
          icon: Icons.dashboard_outlined,
          color: AppTheme.indigo600,
          onTap: () => GoRouter.of(context).go(AppRoutes.analytics),
        ));
        links.add(_DeepLink(
          label: 'Daily Activity',
          icon: Icons.bar_chart_outlined,
          color: AppTheme.indigo600,
          onTap: () => GoRouter.of(context).push(AppRoutes.dailyActivity),
        ));
        links.add(_DeepLink(
          label: 'Insights',
          icon: Icons.insights_outlined,
          color: AppTheme.indigo600,
          onTap: () => GoRouter.of(context).push(AppRoutes.insights),
        ));
        break;
      case 'troubleshooting':
        links.add(_DeepLink(
          label: 'Database Maintenance',
          icon: Icons.build_outlined,
          color: AppTheme.orange600,
          onTap: () => GoRouter.of(context)
              .push(AppRoutes.databaseMaintenance),
        ));
        links.add(_DeepLink(
          label: 'Open Settings',
          icon: Icons.settings_outlined,
          color: AppTheme.orange600,
          onTap: () => GoRouter.of(context).go(AppRoutes.settings),
        ));
        break;
    }

    if (links.isEmpty) return const SizedBox.shrink();

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt_outlined,
                    color: section.iconColor, size: 22),
                const SizedBox(width: AppTheme.spacing3),
                Text('Related Actions', style: AppTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppTheme.spacing3),
            ...links.map((link) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing2),
                child: ManualDeepLinkButton(
                  label: link.label,
                  icon: link.icon,
                  color: link.color,
                  onTap: link.onTap,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Simple data classes for the table of contents and deep links.
class _TocItem {
  final String id;
  final String title;
  const _TocItem({required this.id, required this.title});
}

class _DeepLink {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _DeepLink({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
