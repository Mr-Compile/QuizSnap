import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/search_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTab = 0; // 0: All, 1: Folders, 2: Decks, 3: Flashcards

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Search',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: CustomSearchBar(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            _buildTabBar(),
            Expanded(
              child: _buildSearchResults(),
            ),
          ] else
            Expanded(
              child: EmptyState(
                icon: Icons.search,
                title: 'Search anything',
                subtitle: 'Search for folders, decks, or flashcards',
              ),
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
          _buildTab('All', 0),
          _buildTab('Folders', 1),
          _buildTab('Decks', 2),
          _buildTab('Cards', 3),
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

  Widget _buildSearchResults() {
    return Consumer<DatabaseProvider>(
      builder: (context, dbProvider, child) {
        if (_searchQuery.isEmpty) {
          return const SizedBox.shrink();
        }

        switch (_selectedTab) {
          case 0:
            return _buildAllResults(dbProvider);
          case 1:
            return _buildFolderResults(dbProvider);
          case 2:
            return _buildDeckResults(dbProvider);
          case 3:
            return _buildFlashcardResults(dbProvider);
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildAllResults(DatabaseProvider dbProvider) {
    return ListView(
      children: [
        _buildSectionHeader('Folders'),
        _buildFolderResults(dbProvider),
        _buildSectionHeader('Decks'),
        _buildDeckResults(dbProvider),
        _buildSectionHeader('Flashcards'),
        _buildFlashcardResults(dbProvider),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Text(
        title,
        style: AppTheme.labelLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildFolderResults(DatabaseProvider dbProvider) {
    return FutureBuilder(
      future: dbProvider.folderRepository.searchFolders(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppTheme.spacingLg),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final folders = snapshot.data ?? [];

        if (folders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Text(
              'No folders found',
              style: AppTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: folders.map((folder) {
            return CustomCard(
              onTap: () => _navigateToFolder(context, folder),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(folder.color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.folder,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Text(
                      folder.name,
                      style: AppTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDeckResults(DatabaseProvider dbProvider) {
    return FutureBuilder(
      future: dbProvider.deckRepository.searchDecks(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppTheme.spacingLg),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final decks = snapshot.data ?? [];

        if (decks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Text(
              'No decks found',
              style: AppTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: decks.map((deck) {
            return CustomCard(
              onTap: () => _navigateToDeck(context, deck),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(deck.color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.style,
                      color: Theme.of(context).colorScheme.onPrimary,
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
                        Text(
                          '${deck.cardCount} cards',
                          style: AppTheme.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFlashcardResults(DatabaseProvider dbProvider) {
    return FutureBuilder(
      future: dbProvider.flashcardRepository.searchFlashcards(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppTheme.spacingLg),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final flashcards = snapshot.data ?? [];

        if (flashcards.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Text(
              'No flashcards found',
              style: AppTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: flashcards.map((flashcard) {
            return CustomCard(
              onTap: () => _navigateToFlashcard(context, flashcard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flashcard.question,
                    style: AppTheme.labelLarge,
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
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _navigateToFolder(BuildContext context, dynamic folder) {
    // Navigate to folder details (placeholder - folder details screen not yet implemented)
    // For now, just pop and return the folder
    Navigator.of(context).pop(folder);
  }

  void _navigateToDeck(BuildContext context, dynamic deck) {
    // Navigate to deck details
    context.push('/decks/${deck.id}');
  }

  void _navigateToFlashcard(BuildContext context, dynamic flashcard) {
    // Navigate to flashcard edit/details
    context.push('/decks/${flashcard.deckId}/flashcards/${flashcard.id}/edit');
  }
}
