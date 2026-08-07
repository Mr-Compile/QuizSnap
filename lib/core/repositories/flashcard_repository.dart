import '../database/database.dart';

class FlashcardRepository {
  final AppDatabase _database;

  FlashcardRepository(this._database);

  Future<List<Flashcard>> getAllFlashcards() => _database.getAllFlashcards();

  Future<List<Flashcard>> getFlashcardsByDeck(int deckId) => _database.getFlashcardsByDeck(deckId);

  Future<Flashcard> getFlashcardById(int id) => _database.getFlashcardById(id);

  Future<int> createFlashcard(FlashcardsCompanion flashcard) => _database.createFlashcard(flashcard);

  Future<bool> updateFlashcard(Flashcard flashcard) => _database.updateFlashcard(flashcard);

  Future<void> deleteFlashcard(int id) => _database.deleteFlashcard(id);

  Future<void> restoreFlashcard(int id) => _database.restoreFlashcard(id);

  Future<List<Flashcard>> getDeletedFlashcards() => _database.getDeletedFlashcards();

  Future<List<Flashcard>> getFavoriteFlashcards() => _database.getFavoriteFlashcards();

  Future<List<Flashcard>> getFlashcardsDueForReview() => _database.getFlashcardsDueForReview();

  Future<void> updateFlashcardReview(int id, bool correct) => _database.updateFlashcardReview(id, correct);

  Future<void> updateFlashcardReviewSM2(int id, int quality) => _database.updateFlashcardReviewSM2(id, quality);

  Future<List<Flashcard>> searchFlashcards(String query) => _database.searchFlashcards(query);
}
