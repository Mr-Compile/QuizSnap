import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/trash_provider.dart';
import '../../core/services/dialog_service.dart';

class DeleteFlashcardDialog {
  static Future<void> show({
    required BuildContext context,
    required int flashcardId,
    required int deckId,
  }) async {
    final confirmed = await DialogService.showConfirmation(
      context,
      'This flashcard will be moved to Trash and can be restored later.',
      title: 'Move to Trash',
      confirmAction: 'Move to Trash',
      cancelAction: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final dbProvider = context.read<DatabaseProvider>();
      try {
        await dbProvider.flashcardRepository.deleteFlashcard(flashcardId);
        await dbProvider.deckRepository.updateDeckCardCount(deckId);

        // Refresh active lists and the trash view.
        dbProvider.refreshDecks();
        if (context.mounted) {
          context.read<TrashProvider>().load();
        }

        if (context.mounted) {
          await DialogService.showSuccess(
            context,
            'The flashcard was moved to Trash and can be restored later.',
            title: 'Moved to Trash',
          );
        }
      } catch (e) {
        if (context.mounted) {
          await DialogService.showFriendlyError(
            context,
            'Error deleting flashcard: $e',
            title: 'Delete Failed',
          );
        }
      }
    }
  }
}
