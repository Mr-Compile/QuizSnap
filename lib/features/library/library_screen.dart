import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/database/database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/search_bar.dart';

/// Folder-first Library screen.
///
/// Mental model:
///   Library → Folders → Decks inside each folder.
///
/// There are no standalone (orphan) decks.  A deck must belong to a folder.
/// The Library lists folder cards; tapping a folder opens its details where
/// the decks inside are shown.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryData {
  final List<Folder> folders;
  final List<Deck> decks;

  _LibraryData(this.folders, this.decks);
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<_LibraryData> _dataFuture;
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

  Future<_LibraryData> _loadData() async {
    final dbProvider = context.read<DatabaseProvider>();
    final folders = await dbProvider.folderRepository.getAllFolders();
    final decks = await dbProvider.deckRepository.getAllDecks();
    return _LibraryData(folders, decks);
  }

  void _refresh() {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  /// Returns the deck count for a folder.
  int _deckCountForFolder(int folderId, List<Deck> decks) {
    return decks.where((d) => d.folderId == folderId).length;
  }

  /// Filters folders by the current search query.
  List<Folder> _filterFolders(List<Folder> folders) {
    if (_searchQuery.isEmpty) return folders;
    final q = _searchQuery.toLowerCase();
    return folders.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Library',
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'Manage Folders',
            onPressed: () => GoRouter.of(context).push(AppRoutes.folders),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Trash',
            onPressed: () => GoRouter.of(context).push(AppRoutes.trash),
          ),
        ],
      ),
      body: FutureBuilder<_LibraryData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListSkeleton();
          }

          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final data = snapshot.data!;
          final folders = data.folders;
          final decks = data.decks;

          if (folders.isEmpty && decks.isEmpty) {
            return EmptyState(
              icon: Icons.folder_open,
              title: 'No folders yet',
              subtitle: 'Create your first folder to start organizing decks',
              action: ElevatedButton(
                onPressed: () => _showCreateOptions(context),
                child: const Text('Create'),
              ),
            );
          }

          if (folders.isEmpty && decks.isNotEmpty) {
            // Orphan decks exist but no folders — prompt to create a folder.
            return EmptyState(
              icon: Icons.folder_open,
              title: 'Create a folder',
              subtitle:
                  'You have ${decks.length} deck${decks.length == 1 ? '' : 's'} without a folder. '
                  'Create a folder to organize them.',
              action: ElevatedButton(
                onPressed: () => _navigateToCreateFolder(context),
                child: const Text('Create Folder'),
              ),
            );
          }

          final filteredFolders = _filterFolders(folders);

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppTheme.spacingMd,
                right: AppTheme.spacingMd,
                top: AppTheme.spacingMd,
                bottom: 80 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar — searches folders in the Library scope.
                  CustomSearchBar(
                    controller: _searchController,
                    hintText: 'Search folders...',
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim()),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  if (filteredFolders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingXl,
                      ),
                      child: Center(
                        child: Text(
                          'No folders match "$_searchQuery"',
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
                    ...filteredFolders.map((folder) => _buildFolderCard(
                          context,
                          folder,
                          _deckCountForFolder(folder.id, decks),
                        )),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFolderCard(BuildContext context, Folder folder, int deckCount) {
    final color = Color(int.parse(folder.color.replaceFirst('#', '0xFF')));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: CustomCard(
        onTap: () => _navigateToFolderDetails(context, folder),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color,
              child: const Icon(Icons.folder, color: Colors.white),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    style: AppTheme.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    '$deckCount deck${deckCount == 1 ? '' : 's'}',
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
            Icon(
              Icons.chevron_right,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a Material 3 bottom sheet with the two primary create actions:
  /// Create Deck and Create Folder.
  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingSm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create New', style: AppTheme.headlineSmall),
                const SizedBox(height: AppTheme.spacingMd),
                ListTile(
                  leading: const Icon(Icons.style_outlined),
                  title: const Text('Create Deck'),
                  subtitle: const Text('A new set of flashcards inside a folder'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToCreateDeck(context);
                  },
                ),
                const SizedBox(height: AppTheme.spacingXs),
                ListTile(
                  leading: const Icon(Icons.create_new_folder_outlined),
                  title: const Text('Create Folder'),
                  subtitle: const Text('Organize your decks'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToCreateFolder(context);
                  },
                ),
                const SizedBox(height: AppTheme.spacingMd),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToCreateDeck(BuildContext context) {
    GoRouter.of(context).push(AppRoutes.createDeck);
  }

  void _navigateToCreateFolder(BuildContext context) {
    GoRouter.of(context).push(AppRoutes.createFolder);
  }

  void _navigateToFolderDetails(BuildContext context, Folder folder) {
    GoRouter.of(context).push('/folders/${folder.id}');
  }
}
