import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/trash_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../shared/widgets/confirmation_dialog.dart';

class DeleteFlashcardDialog {
  static Future<void> show({
    required BuildContext context,
    required int flashcardId,
    required int deckId,
  }) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Flashcard',
      message:
          'Are you sure you want to delete this flashcard? This action can be undone from the trash.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
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
            'Flashcard moved to trash',
          );
        }
      } catch (e) {
        if (context.mounted) {
          await DialogService.showError(
            context,
            'Error deleting flashcard: $e',
          );
        }
      }
    }
  }
}
