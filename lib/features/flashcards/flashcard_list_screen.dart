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
import 'add_flashcard_screen.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Flashcards',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: dbProvider.flashcardRepository.getFlashcardsByDeck(widget.deckId),
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
                  icon: Icons.credit_card_outlined,
                  title: 'No flashcards yet',
                  subtitle: 'Add flashcards to this deck to start studying',
                  action: ElevatedButton(
                    onPressed: () => _navigateToAddFlashcard(context),
                    child: const Text('Add Flashcard'),
                  ),
                );
              }

              return ListView.builder(
                itemCount: flashcards.length,
                itemBuilder: (context, index) {
                  final flashcard = flashcards[index];
                  return CustomCard(
                    onTap: () => _navigateToFlashcardDetails(context, flashcard),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                flashcard.question,
                                style: AppTheme.labelLarge,
                              ),
                            ),
                            if (flashcard.isFavorite) ...[
                              const SizedBox(width: AppTheme.spacingSm),
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ],
                          ],
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
                        const SizedBox(height: AppTheme.spacingSm),
                        Row(
                          children: [
                            Icon(
                              Icons.reviews,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(width: AppTheme.spacingXs),
                            Text(
                              '${flashcard.reviewCount} reviews',
                              style: AppTheme.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                              ),
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
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddFlashcard(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddFlashcard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddFlashcardScreen(deckId: widget.deckId),
      ),
    ).then((_) => setState(() {}));
  }

  void _navigateToFlashcardDetails(BuildContext context, dynamic flashcard) {
    // TODO: Navigate to flashcard details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to flashcard: ${flashcard.question}')),
    );
  }
}
