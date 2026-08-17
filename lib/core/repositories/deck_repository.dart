import '../database/database.dart';

class DeckRepository {
  final AppDatabase _database;

  DeckRepository(this._database);

  Future<List<Deck>> getAllDecks() => _database.getAllDecks();

  Future<List<Deck>> getActiveDecks() => _database.getActiveDecks();

  Future<List<Deck>> getDecksByFolder(int folderId) => _database.getDecksByFolder(folderId);

  Future<Deck> getDeckById(int id) => _database.getDeckById(id);

  Future<int> createDeck(DecksCompanion deck) => _database.createDeck(deck);

  Future<bool> updateDeck(Deck deck) => _database.updateDeck(deck);

  Future<void> deleteDeck(int id) => _database.deleteDeck(id);

  Future<void> restoreDeck(int id) => _database.restoreDeck(id);

  Future<void> restoreDeckToFolder(int id, int folderId) => _database.restoreDeckToFolder(id, folderId);

  Future<List<Deck>> getDeletedDecks() => _database.getDeletedDecks();

  Future<void> permanentlyDeleteDeck(int id) => _database.permanentlyDeleteDeck(id);

  Future<void> updateDeckCardCount(int deckId) => _database.updateDeckCardCount(deckId);

  Future<List<Deck>> searchDecks(String query) => _database.searchDecks(query);

  Future<List<Deck>> searchActiveDecks(String query) => _database.searchActiveDecks(query);

  Future<int> getDeckCountForFolder(int folderId) => _database.getDeckCountForFolder(folderId);

  Future<int> getDeckCountWithoutFolder() => _database.getDeckCountWithoutFolder();

  Future<List<Deck>> getDecksWithoutFolder() => _database.getDecksWithoutFolder();

  Future<bool> moveDeckToFolder(int deckId, int? folderId) => _database.moveDeckToFolder(deckId, folderId);

  Future<bool> removeDeckFromFolder(int deckId) => _database.removeDeckFromFolder(deckId);
}
