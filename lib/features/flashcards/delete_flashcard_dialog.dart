import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/success_snackbar.dart';

class DeleteFlashcardDialog {
  static Future<void> show({
    required BuildContext context,
    required int flashcardId,
    required int deckId,
  }) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Flashcard',
      message: 'Are you sure you want to delete this flashcard? This action can be undone from the trash.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      final dbProvider = context.read<DatabaseProvider>();
      try {
        await dbProvider.flashcardRepository.deleteFlashcard(flashcardId);
        await dbProvider.deckRepository.updateDeckCardCount(deckId);
        
        if (context.mounted) {
          SuccessSnackbar.show(
            context,
            message: 'Flashcard moved to trash',
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting flashcard: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
