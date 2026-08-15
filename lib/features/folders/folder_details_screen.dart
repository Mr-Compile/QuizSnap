import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/database/database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/app_routes.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/search_bar.dart';
import 'rename_folder_dialog.dart';

class FolderDetailsScreen extends StatefulWidget {
  final int folderId;

  const FolderDetailsScreen({
    super.key,
    required this.folderId,
  });

  @override
  State<FolderDetailsScreen> createState() => _FolderDetailsScreenState();
}

class _FolderDetailsData {
  final Folder folder;
  final List<Deck> decks;
  final int count;

  _FolderDetailsData(this.folder, this.decks, this.count);
}

class _FolderDetailsScreenState extends State<FolderDetailsScreen> {
  late Future<_FolderDetailsData> _dataFuture;
  DatabaseProvider? _dbProvider;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dbProvider = context.read<DatabaseProvider>();
    if (_dbProvider != dbProvider) {
      _dbProvider?.removeListener(_onProviderChanged);
      _dbProvider = dbProvider;
      _dbProvider?.addListener(_onProviderChanged);
    }
  }

  @override
  void dispose() {
    _dbProvider?.removeListener(_onProviderChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) _refresh();
  }

  Future<_FolderDetailsData> _loadData() async {
    final dbProvider = context.read<DatabaseProvider>();
    final folder = await dbProvider.folderRepository.getFolderById(widget.folderId);
    final decks = await dbProvider.deckRepository.getDecksByFolder(widget.folderId);
    final count = await dbProvider.deckRepository.getDeckCountForFolder(widget.folderId);
    return _FolderDetailsData(folder, decks, count);
  }

  Future<void> _refresh() async {
    setState(() => _dataFuture = _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Folder',
        actions: [
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<_FolderDetailsData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final data = snapshot.data!;
          final folder = data.folder;
          final color = Color(int.parse(folder.color.replaceFirst('#', '0xFF')));

          // Filter decks by search query.
          final decks = _searchQuery.isEmpty
              ? data.decks
              : data.decks
                  .where((d) => d.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(AppTheme.spacingMd),
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (folder.description != null && folder.description!.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          folder.description!,
                          style: AppTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        '${data.count} deck${data.count == 1 ? '' : 's'}',
                        style: AppTheme.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Search bar for decks within this folder.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                  ),
                  child: CustomSearchBar(
                    controller: _searchController,
                    hintText: 'Search decks in this folder...',
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim()),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingSm),
              ),
              if (data.decks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.style_outlined,
                    title: 'No decks in this folder',
                    subtitle: 'Create a deck in this folder to see it here',
                    action: ElevatedButton.icon(
                      onPressed: () => _navigateToCreateDeck(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Deck'),
                    ),
                  ),
                )
              else if (decks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No decks match "$_searchQuery"',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildDeckCard(context, decks[index]),
                    childCount: decks.length,
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateDeck(context),
        tooltip: 'Create Deck in this folder',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDeckCard(BuildContext context, Deck deck) {
    return CustomCard(
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToDeckDetails(context, deck),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(int.parse(deck.color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.style,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.name,
                          style: AppTheme.labelLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          '${deck.cardCount} cards',
                          style: AppTheme.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _onDeckMenuSelected(context, deck, value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'remove', child: Text('Remove from folder')),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToDeckDetails(BuildContext context, Deck deck) {
    GoRouter.of(context).push('/decks/${deck.id}');
  }

  void _navigateToCreateDeck(BuildContext context) {
    GoRouter.of(context).push('${AppRoutes.createDeck}?folderId=${widget.folderId}');
  }

  Future<void> _onMenuSelected(String value) async {
    if (!mounted) return;
    final dbProvider = context.read<DatabaseProvider>();
    final data = await _dataFuture;
    if (!mounted) return;

    if (value == 'rename') {
      final result = await showDialog(
        context: context,
        builder: (context) => RenameFolderDialog(
          folderId: widget.folderId,
          currentName: data.folder.name,
          currentDescription: data.folder.description,
        ),
      );
      if (result == true && mounted) {
        await _refresh();
      }
    } else if (value == 'delete') {
      final confirmed = await DialogService.showConfirmation(
        context,
        'Delete folder "${data.folder.name}"? Decks in this folder will become ungrouped.',
        isDestructive: true,
      );
      if (confirmed != true || !mounted) return;
      try {
        await dbProvider.folderRepository.deleteFolder(widget.folderId);
        dbProvider.refreshAll();
        if (mounted) {
          await DialogService.showSuccess(context, 'Folder deleted');
          if (mounted) GoRouter.of(context).pop();
        }
      } catch (e) {
        if (mounted) DialogService.showError(context, 'Error deleting folder: $e');
      }
    }
  }

  Future<void> _onDeckMenuSelected(BuildContext context, Deck deck, String value) async {
    if (value != 'remove') return;
    if (!context.mounted) return;

    final dbProvider = context.read<DatabaseProvider>();
    try {
      await dbProvider.deckRepository.removeDeckFromFolder(deck.id);
      dbProvider.refreshAll();
      if (!context.mounted) return;
      await DialogService.showSuccess(context, 'Deck removed from folder');
      if (context.mounted) await _refresh();
    } catch (e) {
      if (context.mounted) DialogService.showError(context, 'Error removing deck: $e');
    }
  }
}
