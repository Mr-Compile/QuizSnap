import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'flashcard_list_screen.dart';
import 'quiz_practice_screen.dart';

class DeckStudyScreen extends StatelessWidget {
  const DeckStudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Study by Deck',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: dbProvider.deckRepository.getAllDecks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final decks = snapshot.data ?? [];

              if (decks.isEmpty) {
                return EmptyState(
                  icon: Icons.style_outlined,
                  title: 'No decks available',
                  subtitle: 'Create a deck first to start studying',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                itemCount: decks.length,
                itemBuilder: (context, index) {
                  final deck = decks[index];
                  return CustomCard(
                    onTap: () => _showStudyOptions(context, deck),
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
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showStudyOptions(BuildContext context, dynamic deck) {
    bool shuffle = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Study ${deck.name}',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              SwitchListTile(
                title: const Text('Shuffle cards'),
                subtitle: const Text('Randomize the order of cards for this session'),
                value: shuffle,
                onChanged: (value) =>
                    setSheetState(() => shuffle = value),
                secondary: Icon(
                  Icons.shuffle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FlashcardListScreen(
                        deckId: deck.id,
                        deckName: deck.name,
                        shuffle: shuffle,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.view_list),
                label: const Text('List Mode'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => QuizPracticeScreen(
                        deckId: deck.id,
                        deckName: deck.name,
                        shuffle: shuffle,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.quiz),
                label: const Text('Quiz Mode'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}