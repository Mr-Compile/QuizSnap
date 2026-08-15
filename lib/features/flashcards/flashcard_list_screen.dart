import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/flashcard_selection_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/selectable_flashcard_tile.dart';
import 'add_flashcard_screen.dart';
import 'flashcard_detail_screen.dart';

class _SelectAllIntent extends Intent {
  const _SelectAllIntent();
}

class _DeleteSelectionIntent extends Intent {
  const _DeleteSelectionIntent();
}

class FlashcardListScreen extends StatefulWidget {
  final int deckId;

  const FlashcardListScreen({
    super.key,
    required this.deckId,
  });

  @override
  State<FlashcardListScreen> createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FlashcardListScreen> {
  String _searchQuery = '';
  late FlashcardSelectionProvider _selection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selection = context.read<FlashcardSelectionProvider>();
    _selection.activate(widget.deckId);
  }

  @override
  void dispose() {
    _selection.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FlashcardSelectionProvider>(
      builder: (context, selection, child) {
        return Actions(
          actions: <Type, Action<Intent>>{
            _SelectAllIntent: CallbackAction<_SelectAllIntent>(
              onInvoke: (intent) {
                _selectAll(context, selection);
                return null;
              },
            ),
            _DeleteSelectionIntent: CallbackAction<_DeleteSelectionIntent>(
              onInvoke: (intent) {
                _deleteSelected(context, selection);
                return null;
              },
            ),
          },
          child: Shortcuts(
            shortcuts: <SingleActivator, Intent>{
              const SingleActivator(LogicalKeyboardKey.keyA, control: true): const _SelectAllIntent(),
              const SingleActivator(LogicalKeyboardKey.delete): const _DeleteSelectionIntent(),
            },
            child: Focus(
              autofocus: true,
              child: PopScope(
                canPop: !selection.isSelectionMode,
                onPopInvokedWithResult: (didPop, result) {
                  if (selection.isSelectionMode) {
                    selection.exitSelection();
                  }
                },
                child: Scaffold(
                  appBar: _buildAppBar(context, selection),
                  body: _buildBody(context, selection),
                  floatingActionButton: selection.isSelectionMode
                      ? null
                      : FloatingActionButton(
                          onPressed: () => _navigateToAddFlashcard(context),
                          child: const Icon(Icons.add),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    FlashcardSelectionProvider selection,
  ) {
    if (selection.isSelectionMode) {
      return CustomAppBar(
        title: '${selection.selectedCount} selected',
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: selection.exitSelection,
          tooltip: 'Clear selection',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: () => _selectAll(context, selection),
            tooltip: 'Select all',
          ),
          IconButton(
            icon: const Icon(Icons.drive_file_move),
            onPressed: () => _moveSelected(context, selection),
            tooltip: 'Move',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => _bookmarkSelected(context, selection),
            tooltip: 'Bookmark',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteSelected(context, selection),
            tooltip: 'Delete',
          ),
        ],
      );
    }

    return CustomAppBar(
      title: 'Flashcards',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Trash',
          onPressed: () => GoRouter.of(context).push(AppRoutes.trash),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, FlashcardSelectionProvider selection) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search flashcards',
              hintText: 'Search by question or answer',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: Consumer<DatabaseProvider>(
            builder: (context, dbProvider, child) {
              return FutureBuilder<List<Flashcard>>(
                future: dbProvider.flashcardRepository.getFlashcardsByDeck(widget.deckId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ErrorState(
                      message: snapshot.error.toString(),
                      onRetry: () => setState(() {}),
                    );
                  }

                  final allFlashcards = snapshot.data ?? [];
                  final flashcards = _searchQuery.isEmpty
                      ? allFlashcards
                      : allFlashcards.where((f) {
                          return f.question.toLowerCase().contains(_searchQuery) ||
                              f.answer.toLowerCase().contains(_searchQuery);
                        }).toList();

                  if (flashcards.isEmpty) {
                    return EmptyState(
                      icon: Icons.credit_card_outlined,
                      title: _searchQuery.isEmpty ? 'No flashcards yet' : 'No matches',
                      subtitle: _searchQuery.isEmpty
                          ? 'Add flashcards to this deck to start studying'
                          : 'Try a different search term',
                      action: _searchQuery.isEmpty
                          ? ElevatedButton(
                              onPressed: () => _navigateToAddFlashcard(context),
                              child: const Text('Add Flashcard'),
                            )
                          : null,
                    );
                  }

                  return ListView.builder(
                    itemCount: flashcards.length,
                    itemBuilder: (context, index) {
                      final flashcard = flashcards[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                        child: SelectableFlashcardTile(
                          flashcard: flashcard,
                          onOpen: () => _navigateToFlashcardDetails(context, flashcard),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectAll(BuildContext context, FlashcardSelectionProvider selection) async {
    final db = context.read<DatabaseProvider>();
    final cards = await db.flashcardRepository.getFlashcardsByDeck(widget.deckId);
    selection.selectAll(cards.map((c) => c.id).toList());
  }

  void _moveSelected(BuildContext context, FlashcardSelectionProvider selection) {
    if (selection.selectedIds.isEmpty) return;
    GoRouter.of(context).push(
      AppRoutes.moveFlashcards,
      extra: {
        'flashcardIds': selection.selectedIds.toList(),
        'sourceDeckId': widget.deckId,
      },
    ).then((_) {
      selection.clear();
      setState(() {});
    });
  }

  Future<void> _deleteSelected(BuildContext context, FlashcardSelectionProvider selection) async {
    if (selection.selectedIds.isEmpty) return;

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Move to Trash',
      message: 'Move ${selection.selectedCount} flashcards to Trash?',
      confirmText: 'Move',
      isDestructive: true,
    );

    if (confirmed != true || !context.mounted) return;

    final db = context.read<DatabaseProvider>();
    try {
      for (final id in selection.selectedIds) {
        await db.flashcardRepository.deleteFlashcard(id);
      }
      await db.deckRepository.updateDeckCardCount(widget.deckId);
      db.refreshAll();
      if (!context.mounted) return;
      await DialogService.showSuccess(context, '${selection.selectedCount} flashcards moved to Trash');
      selection.clear();
      setState(() {});
    } catch (e) {
      if (!context.mounted) return;
      await DialogService.showError(context, 'Error moving to Trash: $e');
    }
  }

  Future<void> _bookmarkSelected(BuildContext context, FlashcardSelectionProvider selection) async {
    if (selection.selectedIds.isEmpty) return;

    final db = context.read<DatabaseProvider>();
    try {
      for (final id in selection.selectedIds) {
        final card = await db.flashcardRepository.getFlashcardById(id);
        await db.flashcardRepository.updateFlashcard(
          card.copyWith(isFavorite: !card.isFavorite),
        );
      }
      db.refreshAll();
      if (!context.mounted) return;
      await DialogService.showSuccess(context, '${selection.selectedCount} flashcards bookmarked');
      setState(() {});
    } catch (e) {
      if (!context.mounted) return;
      await DialogService.showError(context, 'Error bookmarking: $e');
    }
  }

  void _navigateToAddFlashcard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddFlashcardScreen(deckId: widget.deckId),
      ),
    ).then((_) => setState(() {}));
  }

  void _navigateToFlashcardDetails(BuildContext context, dynamic flashcard) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardDetailScreen(flashcardId: flashcard.id as int),
      ),
    ).then((_) => setState(() {}));
  }
}
