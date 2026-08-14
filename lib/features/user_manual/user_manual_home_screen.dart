import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import 'manual_content.dart';
import 'manual_widgets.dart';
import 'manual_guide_screen.dart';

/// The User Manual home screen — a searchable dashboard of all guide
/// sections with quick-access cards and deep links to real app screens.
class UserManualHomeScreen extends StatefulWidget {
  const UserManualHomeScreen({super.key});

  @override
  State<UserManualHomeScreen> createState() => _UserManualHomeScreenState();
}

class _UserManualHomeScreenState extends State<UserManualHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ManualSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.trim().isNotEmpty;
      _searchResults = ManualContent.search(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = const [];
    });
  }

  void _openSection(ManualSection section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualGuideScreen(section: section),
      ),
    );
  }

  void _openSearchResult(ManualSearchResult result) {
    final section = ManualContent.getSectionById(result.sectionId);
    if (section != null) {
      _openSection(section);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'User Manual'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth =
                constraints.maxWidth >= 1200 ? 1200.0 : double.infinity;
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _isSearching ? _buildSearchView() : _buildHomeView(),
            );
          },
        ),
      ),
    );
  }

  // ── Home view ────────────────────────────────────────────────────────

  Widget _buildHomeView() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing6),
      children: [
        _buildHeader(),
        const SizedBox(height: AppTheme.spacing4),
        _buildSearchBar(),
        const SizedBox(height: AppTheme.spacing6),
        _buildQuickAccessGrid(),
        const SizedBox(height: AppTheme.spacing6),
        _buildDeepLinksSection(),
        const SizedBox(height: AppTheme.spacing6),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.bambooGreen600.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: AppTheme.bambooGreen600,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QuizSnap User Manual',
                        style: AppTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ManualContent.appTagline,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search the manual...',
        prefixIcon: const Icon(Icons.search_outlined),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
                tooltip: 'Clear search',
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing4,
          vertical: AppTheme.spacing3,
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Access', style: AppTheme.titleMedium),
        const SizedBox(height: AppTheme.spacing3),
        ManualResponsiveGrid(
          children: ManualContent.sections.map((section) {
            return _QuickAccessCard(
              section: section,
              onTap: () => _openSection(section),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDeepLinksSection() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bolt_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: AppTheme.spacing3),
                Text('Quick Actions', style: AppTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppTheme.spacing2),
            Text(
              'Jump directly to key app screens',
              style: AppTheme.bodySmall.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            ManualDeepLinkButton(
              label: 'Open Library',
              icon: Icons.library_books_outlined,
              color: AppTheme.blue600,
              onTap: () => GoRouter.of(context).go(AppRoutes.decks),
            ),
            const SizedBox(height: AppTheme.spacing2),
            ManualDeepLinkButton(
              label: 'Open Study',
              icon: Icons.school_outlined,
              color: AppTheme.emerald600,
              onTap: () => GoRouter.of(context).go(AppRoutes.study),
            ),
            const SizedBox(height: AppTheme.spacing2),
            ManualDeepLinkButton(
              label: 'Open AI Generate',
              icon: Icons.auto_awesome_outlined,
              color: AppTheme.purple600,
              onTap: () => GoRouter.of(context).go(AppRoutes.aiGenerate),
            ),
            const SizedBox(height: AppTheme.spacing2),
            ManualDeepLinkButton(
              label: 'Open Backup & Restore',
              icon: Icons.backup_outlined,
              color: AppTheme.blue600,
              onTap: () => GoRouter.of(context)
                  .push(AppRoutes.backupRestoreEnhanced),
            ),
            const SizedBox(height: AppTheme.spacing2),
            ManualDeepLinkButton(
              label: 'Open Security Settings',
              icon: Icons.security_outlined,
              color: AppTheme.red600,
              onTap: () => GoRouter.of(context).push(AppRoutes.security),
            ),
            const SizedBox(height: AppTheme.spacing2),
            ManualDeepLinkButton(
              label: 'Open Analytics Dashboard',
              icon: Icons.dashboard_outlined,
              color: AppTheme.indigo600,
              onTap: () => GoRouter.of(context).go(AppRoutes.analytics),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.offline_bolt_outlined,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            size: 32,
          ),
          const SizedBox(height: AppTheme.spacing2),
          Text(
            'This manual works fully offline',
            style: AppTheme.bodySmall.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search view ──────────────────────────────────────────────────────

  Widget _buildSearchView() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing6),
      children: [
        _buildSearchBar(),
        const SizedBox(height: AppTheme.spacing4),
        if (_searchResults.isEmpty)
          EmptyState(
            icon: Icons.search_off,
            title: 'No results found',
            subtitle:
                'Try different keywords or browse the quick access cards above.',
            action: TextButton(
              onPressed: _clearSearch,
              child: const Text('Clear search'),
            ),
          )
        else
          ..._searchResults.map((result) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing3),
              child: _SearchResultCard(
                result: result,
                query: _searchController.text,
                onTap: () => _openSearchResult(result),
              ),
            );
          }),
      ],
    );
  }
}

/// A quick-access card on the manual home screen.
class _QuickAccessCard extends StatelessWidget {
  final ManualSection section;
  final VoidCallback onTap;

  const _QuickAccessCard({required this.section, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: section.iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(section.icon, color: section.iconColor, size: 26),
            ),
            const SizedBox(width: AppTheme.spacing3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title, style: AppTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    section.subtitle,
                    style: AppTheme.bodySmall.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// A search result card with highlighted matching text.
class _SearchResultCard extends StatelessWidget {
  final ManualSearchResult result;
  final String query;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.result,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: result.iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(result.icon, color: result.iconColor, size: 22),
            ),
            const SizedBox(width: AppTheme.spacing3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HighlightedText(
                    text: result.topicTitle,
                    query: query,
                    baseStyle: AppTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.sectionTitle,
                    style: AppTheme.labelSmall.copyWith(
                      color: result.iconColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  HighlightedText(
                    text: result.matchedSnippet,
                    query: query,
                    baseStyle: AppTheme.bodySmall.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
