import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'flashcard_card_screen.dart';

class BookmarkListScreen extends StatefulWidget {
  const BookmarkListScreen({super.key});

  @override
  State<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends State<BookmarkListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Bookmarks',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: dbProvider.studyRepository.getBookmarkedFlashcards(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final bookmarkedCards = snapshot.data ?? [];

              if (bookmarkedCards.isEmpty) {
                return EmptyState(
                  icon: Icons.bookmark_border,
                  title: 'No bookmarks yet',
                  subtitle: 'Tap the bookmark icon on any card to save it here',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                itemCount: bookmarkedCards.length,
                itemBuilder: (context, index) {
                  final flashcard = bookmarkedCards[index];
                  return CustomCard(
                    onTap: () => _startStudy(context, bookmarkedCards, index),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: const Icon(
                            Icons.bookmark,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                flashcard.question,
                                style: AppTheme.labelLarge,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppTheme.spacingXs),
                              Text(
                                'Tap to study',
                                style: AppTheme.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            flashcard.isFavorite
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: flashcard.isFavorite
                                ? Colors.blue
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          onPressed: () => _toggleBookmark(context, flashcard.id),
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

  void _startStudy(BuildContext context, List<dynamic> flashcards, int startIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardCardScreen(
          flashcards: flashcards,
          currentIndex: startIndex,
          onCardRated: (quality) {
            // Handle rating for bookmarked cards
            context.read<DatabaseProvider>().studyRepository.updateCardReview(
              flashcards[startIndex].id,
              quality,
            );
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _toggleBookmark(BuildContext context, int id) {
    context.read<DatabaseProvider>().studyRepository.toggleBookmark(id);
    setState(() {});
  }
}