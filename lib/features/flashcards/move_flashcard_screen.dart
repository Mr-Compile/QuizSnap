import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/move_flashcard_provider.dart';
import '../../core/providers/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_skeleton.dart';

class MoveFlashcardScreen extends StatefulWidget {
  final List<int> flashcardIds;
  final int sourceDeckId;

  const MoveFlashcardScreen({
    super.key,
    required this.flashcardIds,
    required this.sourceDeckId,
  });

  @override
  State<MoveFlashcardScreen> createState() => _MoveFlashcardScreenState();
}

class _MoveFlashcardScreenState extends State<MoveFlashcardScreen> {
  int? _selectedDeckId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MoveFlashcardProvider(
        context.read<DatabaseProvider>().flashcardRepository,
      ),
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'Move Flashcards',
        ),
        body: Consumer2<DatabaseProvider, MoveFlashcardProvider>(
          builder: (context, db, moveProvider, child) {
            return FutureBuilder(
              future: db.deckRepository.getActiveDecks(),
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

                final decks = (snapshot.data ?? [])
                    .where((d) => d.id != widget.sourceDeckId)
                    .toList();

                if (decks.isEmpty) {
                  return EmptyState(
                    icon: Icons.style,
                    title: 'No destination decks',
                    subtitle: 'Create another deck to move these cards',
                    action: CustomButton(
                      text: 'Done',
                      onPressed: () => Navigator.of(context).pop(),
                      fullWidth: false,
                    ),
                  );
                }

                return Column(
                  children: [
                    if (moveProvider.error != null)
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        child: MaterialBanner(
                          content: Text('Error: ${moveProvider.error}'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                moveProvider.clearError();
                              },
                              child: const Text('Dismiss'),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        itemCount: decks.length,
                        itemBuilder: (context, index) {
                          final deck = decks[index];
                          final isSelected = _selectedDeckId == deck.id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(
                                  int.parse(deck.color.replaceFirst('#', '0xFF')),
                                ),
                                child: Icon(Icons.style, color: Theme.of(context).colorScheme.onPrimary, size: 18),
                              ),
                              title: Text(deck.name, style: AppTheme.labelLarge),
                              subtitle: Text(
                                '${deck.cardCount} cards',
                                style: AppTheme.bodySmall,
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle,
                                      color: Theme.of(context).colorScheme.primary)
                                  : const Icon(Icons.radio_button_unchecked),
                              onTap: () => setState(() => _selectedDeckId = deck.id),
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        child: CustomButton(
                          text: 'Move ${widget.flashcardIds.length} card${widget.flashcardIds.length == 1 ? '' : 's'}',
                          onPressed: _selectedDeckId == null || moveProvider.isMoving
                              ? null
                              : () => _moveCards(context, moveProvider),
                          fullWidth: true,
                          isLoading: moveProvider.isMoving,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _moveCards(BuildContext context, MoveFlashcardProvider moveProvider) async {
    if (_selectedDeckId == null) return;

    final ok = await moveProvider.moveFlashcards(
      widget.flashcardIds,
      _selectedDeckId!,
    );

    if (!context.mounted) return;

    if (ok) {
      final label = widget.flashcardIds.length == 1
          ? 'Card moved'
          : '${widget.flashcardIds.length} cards moved';
      context.read<NotificationService>().showSuccess(label);
      Navigator.of(context).pop();
    }
  }
}
