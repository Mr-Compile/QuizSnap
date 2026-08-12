import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/notification_service.dart';
import '../../core/providers/trash_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/confirmation_dialog.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  int _selectedTab = 0; // 0: Folders, 1: Decks, 2: Flashcards
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TrashProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Trash',
      ),
      body: Column(
        children: [
          _buildTabBar(),
          _buildSearchBar(),
          _buildBulkActions(),
          Expanded(
            child: _buildTrashContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTab('Folders', 0),
          _buildTab('Decks', 1),
          _buildTab('Cards', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.labelMedium.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingSm,
      ),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Search trash',
          hintText: 'Search by name or question',
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
    );
  }

  Widget _buildBulkActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Restore All',
              icon: Icons.restore,
              onPressed: () { _restoreAll(); },
              fullWidth: true,
              isOutlined: true,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: CustomButton(
              text: 'Empty Trash',
              icon: Icons.delete_forever,
              onPressed: () { _emptyTrash(); },
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashContent() {
    switch (_selectedTab) {
      case 0:
        return _buildFolderTrash();
      case 1:
        return _buildDeckTrash();
      case 2:
        return _buildFlashcardTrash();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFolderTrash() {
    return FutureBuilder(
      future: context.read<DatabaseProvider>().folderRepository.getDeletedFolders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListSkeleton();
        }

        if (snapshot.hasError) {
          return ErrorState(
            message: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        final allFolders = snapshot.data ?? [];
        final folders = _searchQuery.isEmpty
            ? allFolders
            : allFolders
                .where((f) => f.name.toLowerCase().contains(_searchQuery))
                .toList();

        if (folders.isEmpty) {
          return EmptyState(
            icon: Icons.delete_outline,
            title: _searchQuery.isEmpty ? 'No deleted folders' : 'No matching folders',
            subtitle: _searchQuery.isEmpty
                ? 'Folders you delete will appear here'
                : 'Try a different search term',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return CustomCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse(folder.color.replaceFirst('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(
                        Icons.folder,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            folder.name,
                            style: AppTheme.labelLarge,
                          ),
                          if (folder.deletedAt != null) ...[
                            const SizedBox(height: AppTheme.spacingXs),
                            Text(
                              'Deleted ${_formatDate(folder.deletedAt!)}',
                              style: AppTheme.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.restore, size: 20),
                      tooltip: 'Restore folder',
                      onPressed: () => _restoreFolder(context, folder.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, size: 20),
                      tooltip: 'Delete folder forever',
                      onPressed: () => _permanentlyDeleteFolder(context, folder.id),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDeckTrash() {
    return Consumer<TrashProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const ListSkeleton();
        }

        if (provider.error != null) {
          return ErrorState(
            message: provider.error!,
            onRetry: () { provider.load(); },
          );
        }

        final allDecks = provider.deletedDecks;
        final decks = _searchQuery.isEmpty
            ? allDecks
            : allDecks
                .where((d) => d.name.toLowerCase().contains(_searchQuery))
                .toList();

        if (decks.isEmpty) {
          return EmptyState(
            icon: Icons.delete_outline,
            title: _searchQuery.isEmpty ? 'No deleted decks' : 'No matching decks',
            subtitle: _searchQuery.isEmpty
                ? 'Decks you delete will appear here'
                : 'Try a different search term',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.load(),
          child: ListView.builder(
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return CustomCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse(deck.color.replaceFirst('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(
                        Icons.style,
                        color: Colors.white,
                        size: 20,
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
                          ),
                          if (deck.deletedAt != null) ...[
                            const SizedBox(height: AppTheme.spacingXs),
                            Text(
                              'Deleted ${_formatDate(deck.deletedAt!)}',
                              style: AppTheme.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.restore, size: 20),
                      tooltip: 'Restore deck',
                      onPressed: () => _restoreDeck(context, deck.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, size: 20),
                      tooltip: 'Delete deck forever',
                      onPressed: () => _permanentlyDeleteDeck(context, deck.id),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFlashcardTrash() {
    return Consumer<TrashProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const ListSkeleton();
        }

        if (provider.error != null) {
          return ErrorState(
            message: provider.error!,
            onRetry: () { provider.load(); },
          );
        }

        final allFlashcards = provider.deletedFlashcards;
        final flashcards = _searchQuery.isEmpty
            ? allFlashcards
            : allFlashcards
                .where((f) =>
                    f.question.toLowerCase().contains(_searchQuery) ||
                    f.answer.toLowerCase().contains(_searchQuery))
                .toList();

        if (flashcards.isEmpty) {
          return EmptyState(
            icon: Icons.delete_outline,
            title: _searchQuery.isEmpty ? 'No deleted flashcards' : 'No matching flashcards',
            subtitle: _searchQuery.isEmpty
                ? 'Flashcards you delete will appear here'
                : 'Try a different search term',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.load(),
          child: ListView.builder(
            itemCount: flashcards.length,
            itemBuilder: (context, index) {
              final flashcard = flashcards[index];
              return CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flashcard.question,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      flashcard.answer,
                      style: AppTheme.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (flashcard.deletedAt != null) ...[
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        'Deleted ${_formatDate(flashcard.deletedAt!)}',
                        style: AppTheme.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore, size: 20),
                          tooltip: 'Restore flashcard',
                          onPressed: () => _restoreFlashcard(context, flashcard.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, size: 20),
                          tooltip: 'Delete flashcard forever',
                          onPressed: () => _permanentlyDeleteFlashcard(context, flashcard.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _restoreAll() async {
    final notify = context.read<NotificationService>();
    final provider = context.read<TrashProvider>();
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Restore All',
      message: 'Restore all items in Trash?',
      confirmText: 'Restore All',
    );

    if (confirmed && mounted) {
      try {
        await provider.restoreAll();
        if (mounted) {
          notify.showSuccess('All items restored');
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          notify.showErrorTop('Error restoring all: $e');
        }
      }
    }
  }

  Future<void> _emptyTrash() async {
    final notify = context.read<NotificationService>();
    final provider = context.read<TrashProvider>();
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Empty Trash',
      message: 'This action cannot be undone. Permanently delete all items in Trash?',
      confirmText: 'Delete Forever',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      try {
        await provider.emptyTrash();
        if (mounted) {
          notify.showSuccess('Trash emptied');
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          notify.showErrorTop('Error emptying trash: $e');
        }
      }
    }
  }

  void _restoreFolder(BuildContext context, int id) {
    final db = context.read<DatabaseProvider>();
    final notify = context.read<NotificationService>();
    db.folderRepository.restoreFolder(id).then((_) {
      if (mounted) {
        notify.showSuccess('Folder restored');
        setState(() {});
      }
    }).catchError((e) {
      if (mounted) {
        notify.showErrorTop('Error restoring folder: $e');
      }
    });
  }

  void _permanentlyDeleteFolder(BuildContext context, int id) async {
    final notify = context.read<NotificationService>();
    final db = context.read<DatabaseProvider>();
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Permanently Delete',
      message: 'This action cannot be undone. Are you sure you want to permanently delete this folder?',
      confirmText: 'Delete Forever',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      try {
        await db.folderRepository.permanentlyDeleteFolder(id);
        if (mounted) {
          notify.showSuccess('Folder permanently deleted');
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          notify.showErrorTop('Error deleting folder: $e');
        }
      }
    }
  }

  void _restoreDeck(BuildContext context, int id) {
    final notify = context.read<NotificationService>();
    final provider = context.read<TrashProvider>();
    provider.restoreDeck(id).then((_) {
      if (mounted) {
        notify.showSuccess('Deck restored');
        setState(() {});
      }
    }).catchError((e) {
      if (mounted) {
        notify.showErrorTop('Error restoring deck: $e');
      }
    });
  }

  void _permanentlyDeleteDeck(BuildContext context, int id) async {
    final notify = context.read<NotificationService>();
    final provider = context.read<TrashProvider>();
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Permanently Delete',
      message: 'This action cannot be undone. Are you sure you want to permanently delete this deck?',
      confirmText: 'Delete Forever',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      try {
        await provider.permanentlyDeleteDeck(id);
        if (mounted) {
          notify.showSuccess('Deck permanently deleted');
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          notify.showErrorTop('Error deleting deck: $e');
        }
      }
    }
  }

  void _restoreFlashcard(BuildContext context, int id) {
    final notify = context.read<NotificationService>();
    final provider = context.read<TrashProvider>();
    provider.restoreFlashcard(id).then((_) {
      if (mounted) {
        notify.showSuccess('Flashcard restored');
        setState(() {});
      }
    }).catchError((e) {
      if (mounted) {
        notify.showErrorTop('Error restoring flashcard: $e');
      }
    });
  }

  void _permanentlyDeleteFlashcard(BuildContext context, int id) async {
    final notify = context.read<NotificationService>();
    final provider = context.read<TrashProvider>();
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Permanently Delete',
      message: 'This action cannot be undone. Are you sure you want to permanently delete this flashcard?',
      confirmText: 'Delete Forever',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      try {
        await provider.permanentlyDeleteFlashcard(id);
        if (mounted) {
          notify.showSuccess('Flashcard permanently deleted');
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          notify.showErrorTop('Error deleting flashcard: $e');
        }
      }
    }
  }
}
