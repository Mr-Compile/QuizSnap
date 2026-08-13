import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/database/database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
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

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
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
              if (data.decks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.style_outlined,
                    title: 'No decks in this folder',
                    subtitle: 'Move or create a deck in this folder to see it here',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildDeckCard(context, data.decks[index]),
                    childCount: data.decks.length,
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
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
        if (mounted) GoRouter.of(context).pop();
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
      if (!context.mounted) return;
      await DialogService.showSuccess(context, 'Deck removed from folder');
      if (context.mounted) await _refresh();
    } catch (e) {
      if (context.mounted) DialogService.showError(context, 'Error removing deck: $e');
    }
  }
}
