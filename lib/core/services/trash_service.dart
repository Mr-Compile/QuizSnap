import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../repositories/deck_repository.dart';
import '../repositories/flashcard_repository.dart';

/// High-level operations for the Trash system.
///
/// This service coordinates soft-deleted decks and flashcards and ensures
/// referential integrity when restoring or permanently deleting trash.
class TrashService {
  final DeckRepository _deckRepository;
  final FlashcardRepository _flashcardRepository;

  TrashService({
    required this._deckRepository,
    required this._flashcardRepository,
  });

  Future<List<Deck>> getDeletedDecks() => _deckRepository.getDeletedDecks();

  Future<List<Flashcard>> getDeletedFlashcards() =>
      _flashcardRepository.getDeletedFlashcards();

  Future<void> restoreDeck(int id) async {
    await _deckRepository.restoreDeck(id);
  }

  Future<void> restoreFlashcard(int id) async {
    await _flashcardRepository.restoreFlashcard(id);
  }

  Future<void> permanentlyDeleteDeck(int id) async {
    await _deckRepository.permanentlyDeleteDeck(id);
  }

  Future<void> permanentlyDeleteFlashcard(int id) async {
    await _flashcardRepository.permanentlyDeleteFlashcard(id);
  }

  Future<void> emptyTrash() async {
    final deletedDecks = await _deckRepository.getDeletedDecks();
    for (final deck in deletedDecks) {
      try {
        await _deckRepository.permanentlyDeleteDeck(deck.id);
      } catch (e) {
        debugPrint('Error deleting deck ${deck.id}: $e');
      }
    }

    final deletedFlashcards = await _flashcardRepository.getDeletedFlashcards();
    for (final card in deletedFlashcards) {
      try {
        await _flashcardRepository.permanentlyDeleteFlashcard(card.id);
      } catch (e) {
        debugPrint('Error deleting flashcard ${card.id}: $e');
      }
    }
  }

  Future<void> restoreAll() async {
    final deletedDecks = await _deckRepository.getDeletedDecks();
    for (final deck in deletedDecks) {
      try {
        await _deckRepository.restoreDeck(deck.id);
      } catch (e) {
        debugPrint('Error restoring deck ${deck.id}: $e');
      }
    }

    final deletedFlashcards = await _flashcardRepository.getDeletedFlashcards();
    for (final card in deletedFlashcards) {
      try {
        await _flashcardRepository.restoreFlashcard(card.id);
      } catch (e) {
        debugPrint('Error restoring flashcard ${card.id}: $e');
      }
    }
  }
}
