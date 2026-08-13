import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/database/database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/deck_bookmark_provider.dart';
import '../../core/providers/flashcard_selection_provider.dart';
import '../../core/providers/notification_service.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/selectable_flashcard_tile.dart';
import 'deck_details_tablet_layout.dart';
import 'edit_deck_screen.dart';
import 'selection_preview_pane.dart';
import '../exam/exam_setup_screen.dart';
import '../flashcards/add_flashcard_screen.dart';
import '../flashcards/flashcard_detail_screen.dart';
import '../study/flashcard_study_session_screen.dart';

class _SelectAllIntent extends Intent {
  const _SelectAllIntent();
}

class _DeleteSelectionIntent extends Intent {
  const _DeleteSelectionIntent();
}

class _MoveSelectionIntent extends Intent {
  const _MoveSelectionIntent();
}

class _BookmarkSelectionIntent extends Intent {
  const _BookmarkSelectionIntent();
}

class _ExitSelectionIntent extends Intent {
  const _ExitSelectionIntent();
}

class DeckDetailsScreen extends StatefulWidget {
  final int deckId;

  const DeckDetailsScreen({
    super.key,
    required this.deckId,
  });

  @override
  State<DeckDetailsScreen> createState() => _DeckDetailsScreenState();
}

class _DeckDetailsScreenState extends State<DeckDetailsScreen> {
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
            _MoveSelectionIntent: CallbackAction<_MoveSelectionIntent>(
              onInvoke: (intent) {
                _moveSelected(context, selection);
                return null;
              },
            ),
            _BookmarkSelectionIntent: CallbackAction<_BookmarkSelectionIntent>(
              onInvoke: (intent) {
                _bookmarkSelected(context, selection);
                return null;
              },
            ),
            _ExitSelectionIntent: CallbackAction<_ExitSelectionIntent>(
              onInvoke: (intent) {
                selection.exitSelection();
                return null;
              },
            ),
          },
          child: Shortcuts(
            shortcuts: <SingleActivator, Intent>{
              const SingleActivator(LogicalKeyboardKey.keyA, control: true): const _SelectAllIntent(),
              const SingleActivator(LogicalKeyboardKey.delete): const _DeleteSelectionIntent(),
              const SingleActivator(LogicalKeyboardKey.keyM, control: true): const _MoveSelectionIntent(),
              const SingleActivator(LogicalKeyboardKey.keyB, control: true): const _BookmarkSelectionIntent(),
              const SingleActivator(LogicalKeyboardKey.escape): const _ExitSelectionIntent(),
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
        leading: Semantics(
          button: true,
          label: 'Clear selection and exit selection mode',
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: selection.exitSelection,
            tooltip: 'Clear selection',
          ),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Select all flashcards in deck',
            child: IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () => _selectAll(context, selection),
              tooltip: 'Select all',
            ),
          ),
          Semantics(
            button: true,
            label: 'Move selected flashcards to another deck',
            child: IconButton(
              icon: const Icon(Icons.drive_file_move),
              onPressed: () => _moveSelected(context, selection),
              tooltip: 'Move',
            ),
          ),
          Semantics(
            button: true,
            label: 'Bookmark selected flashcards',
            child: IconButton(
              icon: const Icon(Icons.bookmark),
              onPressed: () => _bookmarkSelected(context, selection),
              tooltip: 'Bookmark',
            ),
          ),
          Semantics(
            button: true,
            label: 'Delete selected flashcards',
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteSelected(context, selection),
              tooltip: 'Delete',
            ),
          ),
        ],
      );
    }

    return CustomAppBar(
      title: 'Deck Details',
      actions: [
        Consumer<DeckBookmarkProvider>(
          builder: (context, bookmarks, _) {
            final isBookmarked = bookmarks.isBookmarked(widget.deckId);
            return Semantics(
              button: true,
              label: isBookmarked ? 'Remove bookmark from deck' : 'Bookmark deck',
              child: IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: () async {
                  await bookmarks.toggleBookmark(widget.deckId);
                  if (context.mounted) {
                    context.read<NotificationService>().showSuccess(
                      isBookmarked ? 'Bookmark removed' : 'Deck bookmarked',
                    );
                  }
                },
                tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark deck',
              ),
            );
          },
        ),
        Semantics(
          button: true,
          label: 'Edit deck',
          child: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditDeck(context),
            tooltip: 'Edit deck',
          ),
        ),
        Semantics(
          button: true,
          label: 'Delete deck',
          child: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
            tooltip: 'Delete deck',
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, FlashcardSelectionProvider selection) {
    return Consumer<DatabaseProvider>(
      builder: (context, dbProvider, child) {
        return FutureBuilder(
          future: dbProvider.deckRepository.getDeckById(widget.deckId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CardSkeleton();
            }

            if (snapshot.hasError) {
              return ErrorState(
                message: snapshot.error.toString(),
                onRetry: () => setState(() {}),
              );
            }

            final deck = snapshot.data;

            if (deck == null) {
              return const EmptyState(
                icon: Icons.error_outline,
                title: 'Deck not found',
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Color(int.parse(deck.color.replaceFirst('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Icon(
                          Icons.style,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingLg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deck.name,
                              style: AppTheme.textMedium,
                            ),
                            if (deck.description != null) ...[
                              const SizedBox(height: AppTheme.spacingXs),
                              Text(
                                deck.description!,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistics',
                          style: AppTheme.labelLarge,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat(
                              context,
                              Icons.credit_card,
                              '${deck.cardCount}',
                              'Cards',
                            ),
                            _buildStat(
                              context,
                              Icons.folder,
                              deck.folderId != null ? 'In Folder' : 'No Folder',
                              'Location',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  CustomCard(
                    child: CustomButton(
                      text: deck.cardCount > 0 ? 'Start Exam' : 'No cards to start',
                      onPressed: deck.cardCount > 0
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ExamSetupScreen(
                                    deckId: widget.deckId,
                                    deckName: deck.name,
                                  ),
                                ),
                              );
                            }
                          : null,
                      icon: Icons.quiz,
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    'Flashcards',
                    style: AppTheme.labelLarge,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  FutureBuilder(
                    future: dbProvider.flashcardRepository.getFlashcardsByDeck(widget.deckId),
                    builder: (context, flashcardSnapshot) {
                      if (flashcardSnapshot.connectionState == ConnectionState.waiting) {
                        return const ListSkeleton(itemCount: 3);
                      }

                      final flashcards = flashcardSnapshot.data ?? [];

                      if (flashcards.isEmpty) {
                        return EmptyState(
                          icon: Icons.credit_card_outlined,
                          title: 'No flashcards yet',
                          subtitle: 'Add flashcards to this deck to start studying',
                          action: CustomButton(
                            text: 'Add Flashcard',
                            onPressed: () => _addFlashcard(context),
                            icon: Icons.add,
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isTablet = constraints.maxWidth >= 600;
                          if (isTablet && selection.isSelectionMode) {
                            return DeckDetailsTabletLayout(
                              left: _buildFlashcardList(context, deck, flashcards, selection),
                              right: SelectionPreviewPane(
                                flashcards: flashcards,
                                selection: selection,
                                onMove: () => _moveSelected(context, selection),
                                onDelete: () => _deleteSelected(context, selection),
                                onBookmark: () => _bookmarkSelected(context, selection),
                              ),
                            );
                          }
                          return _buildFlashcardList(context, deck, flashcards, selection);
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFlashcardList(
    BuildContext context,
    Deck deck,
    List<Flashcard> flashcards,
    FlashcardSelectionProvider selection,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Study Deck',
                onPressed: () => _startStudySession(context, deck.name, flashcards),
                icon: Icons.school,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: CustomButton(
                text: 'Manage',
                onPressed: () => _navigateToFlashcards(context),
                isOutlined: true,
                icon: Icons.list,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: flashcards.length,
          itemBuilder: (context, index) {
            final flashcard = flashcards[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: SelectableFlashcardTile(
                flashcard: flashcard,
                onOpen: () => _navigateToFlashcardDetail(context, flashcard.id),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          value,
          style: AppTheme.textSmall,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
    final notify = context.read<NotificationService>();
    try {
      for (final id in selection.selectedIds) {
        await db.flashcardRepository.deleteFlashcard(id);
      }
      await db.deckRepository.updateDeckCardCount(widget.deckId);
      notify.showSuccess('${selection.selectedCount} flashcards moved to Trash');
      selection.clear();
      setState(() {});
    } catch (e) {
      notify.showErrorTop('Error moving to Trash: $e');
    }
  }

  Future<void> _bookmarkSelected(BuildContext context, FlashcardSelectionProvider selection) async {
    if (selection.selectedIds.isEmpty) return;

    final db = context.read<DatabaseProvider>();
    final notify = context.read<NotificationService>();
    try {
      for (final id in selection.selectedIds) {
        final card = await db.flashcardRepository.getFlashcardById(id);
        await db.flashcardRepository.updateFlashcard(
          card.copyWith(isFavorite: !card.isFavorite),
        );
      }
      notify.showSuccess('${selection.selectedCount} flashcards bookmarked');
      setState(() {});
    } catch (e) {
      notify.showErrorTop('Error bookmarking: $e');
    }
  }

  void _navigateToEditDeck(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditDeckScreen(deckId: widget.deckId),
      ),
    ).then((_) => setState(() {}));
  }

  void _confirmDelete(BuildContext context) async {
    final notify = context.read<NotificationService>();
    final dbProvider = context.read<DatabaseProvider>();
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Move deck to Trash?',
      message: 'The deck and all flashcards inside it will be moved to Trash. You can restore them later.',
      confirmText: 'Move to Trash',
      isDestructive: true,
    );

    if (confirmed) {
      if (!context.mounted) return;
      try {
        await dbProvider.deckRepository.deleteDeck(widget.deckId);
        dbProvider.refreshDecks();
        if (context.mounted) {
          notify.showSuccess('Deck moved to trash');
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          notify.showErrorTop('Error deleting deck: $e');
        }
      }
    }
  }

  void _navigateToFlashcards(BuildContext context) {
    context.go('/decks/${widget.deckId}/flashcards');
  }

  void _navigateToFlashcardDetail(BuildContext context, int flashcardId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardDetailScreen(flashcardId: flashcardId),
      ),
    ).then((_) => setState(() {}));
  }

  void _addFlashcard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddFlashcardScreen(deckId: widget.deckId),
      ),
    ).then((_) => setState(() {}));
  }

  void _startStudySession(BuildContext context, String deckName, List<Flashcard> flashcards) {
    if (flashcards.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardStudySessionScreen(
          flashcards: flashcards,
          deckId: widget.deckId,
          deckName: deckName,
        ),
      ),
    ).then((_) => setState(() {}));
  }
}
