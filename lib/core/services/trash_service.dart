import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../repositories/deck_repository.dart';
import '../repositories/flashcard_repository.dart';
import '../repositories/folder_repository.dart';

/// High-level operations for the Trash system.
///
/// This service coordinates soft-deleted folders, decks, and flashcards
/// and ensures referential integrity when restoring or permanently
/// deleting trash.
class TrashService {
  final DeckRepository deckRepository;
  final FlashcardRepository flashcardRepository;
  final FolderRepository? folderRepository;

  TrashService({
    required this.deckRepository,
    required this.flashcardRepository,
    this.folderRepository,
  });

  Future<List<Deck>> getDeletedDecks() => deckRepository.getDeletedDecks();

  Future<List<Flashcard>> getDeletedFlashcards() =>
      flashcardRepository.getDeletedFlashcards();

  Future<List<Folder>> getDeletedFolders() async {
    if (folderRepository == null) return [];
    return folderRepository!.getDeletedFolders();
  }

  Future<void> restoreDeck(int id) async {
    await deckRepository.restoreDeck(id);
  }

  Future<void> restoreFlashcard(int id) async {
    await flashcardRepository.restoreFlashcard(id);
  }

  Future<void> restoreFolder(int id) async {
    if (folderRepository == null) return;
    await folderRepository!.restoreFolder(id);
  }

  Future<void> permanentlyDeleteDeck(int id) async {
    await deckRepository.permanentlyDeleteDeck(id);
  }

  Future<void> permanentlyDeleteFlashcard(int id) async {
    await flashcardRepository.permanentlyDeleteFlashcard(id);
  }

  Future<void> permanentlyDeleteFolder(int id) async {
    if (folderRepository == null) return;
    await folderRepository!.permanentlyDeleteFolder(id);
  }

  Future<void> emptyTrash() async {
    // Folders
    if (folderRepository != null) {
      final deletedFolders = await folderRepository!.getDeletedFolders();
      for (final folder in deletedFolders) {
        try {
          await folderRepository!.permanentlyDeleteFolder(folder.id);
        } catch (e) {
          debugPrint('Error deleting folder ${folder.id}: $e');
        }
      }
    }

    final deletedDecks = await deckRepository.getDeletedDecks();
    for (final deck in deletedDecks) {
      try {
        await deckRepository.permanentlyDeleteDeck(deck.id);
      } catch (e) {
        debugPrint('Error deleting deck ${deck.id}: $e');
      }
    }

    final deletedFlashcards = await flashcardRepository.getDeletedFlashcards();
    for (final card in deletedFlashcards) {
      try {
        await flashcardRepository.permanentlyDeleteFlashcard(card.id);
      } catch (e) {
        debugPrint('Error deleting flashcard ${card.id}: $e');
      }
    }
  }

  Future<void> restoreAll() async {
    // Folders first so their child decks have an active parent.
    if (folderRepository != null) {
      final deletedFolders = await folderRepository!.getDeletedFolders();
      for (final folder in deletedFolders) {
        try {
          await folderRepository!.restoreFolder(folder.id);
        } catch (e) {
          debugPrint('Error restoring folder ${folder.id}: $e');
        }
      }
    }

    // Only restore decks whose parent folder is still active to avoid orphans.
    final activeFolderIds = folderRepository != null
        ? (await folderRepository!.getAllFolders()).map((f) => f.id).toSet()
        : <int>{};
    final deletedDecks = await deckRepository.getDeletedDecks();
    for (final deck in deletedDecks) {
      if (deck.folderId == null || !activeFolderIds.contains(deck.folderId)) {
        debugPrint('Skipping restore of deck ${deck.id}: folder not active');
        continue;
      }
      try {
        await deckRepository.restoreDeck(deck.id);
      } catch (e) {
        debugPrint('Error restoring deck ${deck.id}: $e');
      }
    }

    final deletedFlashcards = await flashcardRepository.getDeletedFlashcards();
    for (final card in deletedFlashcards) {
      try {
        await flashcardRepository.restoreFlashcard(card.id);
      } catch (e) {
        debugPrint('Error restoring flashcard ${card.id}: $e');
      }
    }
  }
}
