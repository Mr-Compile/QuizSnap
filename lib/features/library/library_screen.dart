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

  // 0 = All Decks panel, a positive id = folder, null = all collapsed.
  int? _selectedPanelValue = 0;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_LibraryData> _loadData() async {
    final dbProvider = context.read<DatabaseProvider>();
    final folders = await dbProvider.folderRepository.getAllFolders();
    final decks = await dbProvider.deckRepository.getAllDecks();
    return _LibraryData(folders, decks);
  }

  void _refresh() {
    setState(() => _dataFuture = _loadData());
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

          if (decks.isEmpty && folders.isEmpty) {
            return EmptyState(
              icon: Icons.style_outlined,
              title: 'No decks yet',
              subtitle: 'Create your first deck or folder to start studying',
              action: ElevatedButton(
                onPressed: () => _navigateToCreateDeck(context),
                child: const Text('Create Deck'),
              ),
            );
          }

          final counts = _buildCounts(folders, decks);
          final allCount = decks.length;

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
                  _buildFolderChips(folders, counts, allCount),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildExpansionPanels(folders, decks, counts),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateDeck(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Map<int, int> _buildCounts(List<Folder> folders, List<Deck> decks) {
    final counts = {for (final folder in folders) folder.id: 0};
    for (final deck in decks) {
      if (deck.folderId != null) {
        counts[deck.folderId!] = (counts[deck.folderId!] ?? 0) + 1;
      }
    }
    return counts;
  }

  Widget _buildFolderChips(List<Folder> folders, Map<int, int> counts, int allCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingSm),
            child: ChoiceChip(
              label: Text('All Decks ($allCount)'),
              selected: _selectedPanelValue == 0,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedPanelValue = 0);
                }
              },
            ),
          ),
          ...folders.map((folder) {
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSm),
              child: ChoiceChip(
                label: Text('${folder.name} (${counts[folder.id] ?? 0})'),
                selected: _selectedPanelValue == folder.id,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedPanelValue = folder.id);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExpansionPanels(List<Folder> folders, List<Deck> decks, Map<int, int> counts) {
    final deckMap = <int, List<Deck>>{};
    for (final folder in folders) {
      deckMap[folder.id] = decks.where((d) => d.folderId == folder.id).toList();
    }

    final allDecks = decks;
    final panelValues = <int>[0, ...folders.map((f) => f.id)];

    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          if (isExpanded) {
            _selectedPanelValue = null;
          } else {
            _selectedPanelValue = panelValues[index];
          }
        });
      },
      children: [
        _buildAllDecksPanel(allDecks),
        ...folders.map((folder) {
          return _buildFolderPanel(folder, deckMap[folder.id] ?? [], counts[folder.id] ?? 0);
        }),
      ],
    );
  }

  ExpansionPanel _buildAllDecksPanel(List<Deck> decks) {
    return ExpansionPanel(
      canTapOnHeader: true,
      isExpanded: _selectedPanelValue == 0,
      headerBuilder: (context, isExpanded) {
        return ListTile(
          leading: const Icon(Icons.library_books),
          title: const Text('All Decks'),
          trailing: Text('${decks.length}'),
        );
      },
      body: decks.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppTheme.spacingLg),
              child: Center(child: Text('No decks yet')),
            )
          : _buildDeckList(decks),
    );
  }

  ExpansionPanel _buildFolderPanel(Folder folder, List<Deck> decks, int count) {
    final color = Color(int.parse(folder.color.replaceFirst('#', '0xFF')));

    return ExpansionPanel(
      canTapOnHeader: true,
      isExpanded: _selectedPanelValue == folder.id,
      headerBuilder: (context, isExpanded) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color,
            child: const Icon(Icons.folder, color: Colors.white),
          ),
          title: Text(folder.name),
          trailing: Text('$count'),
        );
      },
      body: decks.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Center(child: Text('No decks in ${folder.name}')),
            )
          : _buildDeckList(decks),
    );
  }

  Widget _buildDeckList(List<Deck> decks) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: decks.length,
      itemBuilder: (context, index) => _buildDeckCard(context, decks[index]),
    );
  }

  Widget _buildDeckCard(BuildContext context, Deck deck) {
    return CustomCard(
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
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateDeck(BuildContext context) {
    GoRouter.of(context).push(AppRoutes.createDeck);
  }

  void _navigateToDeckDetails(BuildContext context, Deck deck) {
    GoRouter.of(context).push('/decks/${deck.id}');
  }
}
