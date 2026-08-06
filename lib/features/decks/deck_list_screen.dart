import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/success_snackbar.dart';
import 'create_deck_screen.dart';

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
          return FutureBuilder(
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

              return ListView.builder(
                itemCount: decks.length,
                itemBuilder: (context, index) {
                  final deck = decks[index];
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
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: AppTheme.spacingXs),
                                  Text(
                                    '${deck.cardCount} cards',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateDeck(context),
        child: const Icon(Icons.add),
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
    // TODO: Navigate to deck details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to ${deck.name}')),
    );
  }
}
