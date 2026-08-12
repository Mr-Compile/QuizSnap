import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/deck_bookmark_provider.dart';
import '../../core/providers/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/success_snackbar.dart';
import 'edit_deck_screen.dart';
import '../exam/exam_setup_screen.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Deck Details',
        actions: [
          Consumer<DeckBookmarkProvider>(
            builder: (context, bookmarks, _) {
              final isBookmarked = bookmarks.isBookmarked(widget.deckId);
              return IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: () => bookmarks.toggleBookmark(widget.deckId),
                tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark deck',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditDeck(context),
            tooltip: 'Edit deck',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
            tooltip: 'Delete deck',
          ),
        ],
      ),
      body: Consumer<DatabaseProvider>(
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
                          child: const Icon(
                            Icons.style,
                            color: Colors.white,
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
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: flashcards.length,
                          itemBuilder: (context, index) {
                            final flashcard = flashcards[index];
                            return CustomCard(
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
      ),
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

  void _navigateToEditDeck(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditDeckScreen(deckId: widget.deckId),
      ),
    ).then((_) => setState(() {}));
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Deck',
      message: 'Are you sure you want to delete this deck? This action can be undone from the trash.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed) {
      if (!mounted) return;
      final dbProvider = this.context.read<DatabaseProvider>();
      try {
        await dbProvider.deckRepository.deleteDeck(widget.deckId);
        if (mounted) {
          SuccessSnackbar.show(
            this.context,
            message: 'Deck moved to trash',
          );
          Navigator.of(this.context).pop();
        }
      } catch (e) {
        if (mounted) {
          this.context.read<NotificationService>().showErrorTop('Error deleting deck: $e');
        }
      }
    }
  }
}
