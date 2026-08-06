import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/success_snackbar.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  int _selectedTab = 0; // 0: Folders, 1: Decks, 2: Flashcards

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Trash',
      ),
      body: Column(
        children: [
          _buildTabBar(),
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
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrashContent() {
    return Consumer<DatabaseProvider>(
      builder: (context, dbProvider, child) {
        switch (_selectedTab) {
          case 0:
            return _buildFolderTrash(dbProvider);
          case 1:
            return _buildDeckTrash(dbProvider);
          case 2:
            return _buildFlashcardTrash(dbProvider);
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildFolderTrash(DatabaseProvider dbProvider) {
    return FutureBuilder(
      future: dbProvider.folderRepository.getDeletedFolders(),
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

        final folders = snapshot.data ?? [];

        if (folders.isEmpty) {
          return EmptyState(
            icon: Icons.delete_outline,
            title: 'No deleted folders',
            subtitle: 'Folders you delete will appear here',
          );
        }

        return ListView.builder(
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
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.restore, size: 20),
                    onPressed: () => _restoreFolder(context, folder.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, size: 20),
                    onPressed: () => _permanentlyDeleteFolder(context, folder.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeckTrash(DatabaseProvider dbProvider) {
    return FutureBuilder(
      future: dbProvider.deckRepository.getDeletedDecks(),
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

        final decks = snapshot.data ?? [];

        if (decks.isEmpty) {
          return EmptyState(
            icon: Icons.delete_outline,
            title: 'No deleted decks',
            subtitle: 'Decks you delete will appear here',
          );
        }

        return ListView.builder(
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
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.restore, size: 20),
                    onPressed: () => _restoreDeck(context, deck.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, size: 20),
                    onPressed: () => _permanentlyDeleteDeck(context, deck.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFlashcardTrash(DatabaseProvider dbProvider) {
    return FutureBuilder(
      future: dbProvider.flashcardRepository.getDeletedFlashcards(),
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

        final flashcards = snapshot.data ?? [];

        if (flashcards.isEmpty) {
          return EmptyState(
            icon: Icons.delete_outline,
            title: 'No deleted flashcards',
            subtitle: 'Flashcards you delete will appear here',
          );
        }

        return ListView.builder(
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (flashcard.deletedAt != null) ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Deleted ${_formatDate(flashcard.deletedAt!)}',
                      style: AppTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore, size: 20),
                        onPressed: () => _restoreFlashcard(context, flashcard.id, flashcard.deckId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, size: 20),
                        onPressed: () => _permanentlyDeleteFlashcard(context, flashcard.id),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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

  void _restoreFolder(BuildContext context, int id) async {
    final dbProvider = context.read<DatabaseProvider>();
    try {
      await dbProvider.folderRepository.restoreFolder(id);
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: 'Folder restored successfully',
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring folder: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _permanentlyDeleteFolder(BuildContext context, int id) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Permanently Delete',
      message: 'This action cannot be undone. Are you sure you want to permanently delete this folder?',
      confirmText: 'Delete Forever',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      // TODO: Implement permanent deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permanent deletion not implemented yet')),
      );
    }
  }

  void _restoreDeck(BuildContext context, int id) async {
    final dbProvider = context.read<DatabaseProvider>();
    try {
      await dbProvider.deckRepository.restoreDeck(id);
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: 'Deck restored successfully',
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring deck: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _permanentlyDeleteDeck(BuildContext context, int id) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Permanently Delete',
      message: 'This action cannot be undone. Are you sure you want to permanently delete this deck?',
      confirmText: 'Delete Forever',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      // TODO: Implement permanent deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permanent deletion not implemented yet')),
      );
    }
  }

  void _restoreFlashcard(BuildContext context, int id, int deckId) async {
    final dbProvider = context.read<DatabaseProvider>();
    try {
      await dbProvider.flashcardRepository.restoreFlashcard(id);
      await dbProvider.deckRepository.updateDeckCardCount(deckId);
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: 'Flashcard restored successfully',
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring flashcard: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _permanentlyDeleteFlashcard(BuildContext context, int id) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Permanently Delete',
      message: 'This action cannot be undone. Are you sure you want to permanently delete this flashcard?',
      confirmText: 'Delete Forever',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      // TODO: Implement permanent deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permanent deletion not implemented yet')),
      );
    }
  }
}
