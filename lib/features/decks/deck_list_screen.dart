import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/deck_bookmark_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/error_state.dart';
import 'create_deck_screen.dart';
import 'deck_details_screen.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Decks',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder<List<Deck>>(
            future: dbProvider.deckRepository.getAllDecks(),
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
                  icon: Icons.style_outlined,
                  title: 'No decks yet',
                  subtitle: 'Create your first deck to start studying',
                  action: ElevatedButton(
                    onPressed: () => _navigateToCreateDeck(context),
                    child: const Text('Create Deck'),
                  ),
                );
              }

              return Consumer<DeckBookmarkProvider>(
                builder: (context, bookmarkProvider, _) {
                  final sorted = bookmarkProvider.sortBookmarkedFirst(
                    decks,
                    (deck) => deck.id,
                  );
                  final bookmarked = sorted.where((d) => bookmarkProvider.isBookmarked(d.id)).toList();
                  final others = sorted.where((d) => !bookmarkProvider.isBookmarked(d.id)).toList();

                  return ListView(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    children: [
                      if (bookmarked.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                          child: Text(
                            'Bookmarked Decks',
                            style: AppTheme.labelLarge.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        ...bookmarked.map((deck) => _buildDeckCard(context, deck, bookmarkProvider)),
                        const SizedBox(height: AppTheme.spacingLg),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                        child: Text(
                          'All Decks',
                          style: AppTheme.labelLarge.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      ...others.map((deck) => _buildDeckCard(context, deck, bookmarkProvider)),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateDeck(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDeckCard(BuildContext context, Deck deck, DeckBookmarkProvider bookmarkProvider) {
    final isBookmarked = bookmarkProvider.isBookmarked(deck.id);

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
            child: const Icon(
              Icons.style,
              color: Colors.white,
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
                const SizedBox(height: AppTheme.spacingXs),
                Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      '${deck.cardCount} cards',
                      style: AppTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            onPressed: () => bookmarkProvider.toggleBookmark(deck.id),
            tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark deck',
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateDeckScreen(),
      ),
    ).then((_) => setState(() {}));
  }

  void _navigateToDeckDetails(BuildContext context, dynamic deck) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeckDetailsScreen(deckId: deck.id),
      ),
    );
  }
}
