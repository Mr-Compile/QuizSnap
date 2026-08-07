import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'flashcard_card_screen.dart';

class FlashcardListScreen extends StatefulWidget {
  final int deckId;
  final String deckName;

  const FlashcardListScreen({
    super.key,
    required this.deckId,
    required this.deckName,
  });

  @override
  State<FlashcardListScreen> createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FlashcardListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.deckName,
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: dbProvider.studyRepository.getFlashcardsByDeck(widget.deckId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final flashcards = snapshot.data ?? [];

              if (flashcards.isEmpty) {
                return EmptyState(
                  icon: Icons.credit_card,
                  title: 'No cards in this deck',
                  subtitle: 'Add some flashcards to start studying',
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${flashcards.length} cards',
                          style: AppTheme.labelMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _startStudy(context, flashcards),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Study All'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      itemCount: flashcards.length,
                      itemBuilder: (context, index) {
                        final flashcard = flashcards[index];
                        return CustomCard(
                          onTap: () => _viewCard(context, flashcards, index),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                flashcard.question,
                                style: AppTheme.labelLarge,
                              ),
                              const SizedBox(height: AppTheme.spacingSm),
                              Container(
                                height: 1,
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: AppTheme.spacingSm),
                              Text(
                                flashcard.answer,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                              if (flashcard.isFavorite) ...[
                                const SizedBox(height: AppTheme.spacingSm),
                                Icon(
                                  Icons.bookmark,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _startStudy(BuildContext context, List<dynamic> flashcards) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardCardScreen(
          flashcards: flashcards,
          currentIndex: 0,
          onCardRated: (quality) {
            context.read<DatabaseProvider>().studyRepository.updateCardReview(
              flashcards[0].id,
              quality,
            );
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _viewCard(BuildContext context, List<dynamic> flashcards, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardCardScreen(
          flashcards: flashcards,
          currentIndex: index,
          onCardRated: (quality) {
            context.read<DatabaseProvider>().studyRepository.updateCardReview(
              flashcards[index].id,
              quality,
            );
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}