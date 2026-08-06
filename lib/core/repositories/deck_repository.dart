import '../database/database.dart';

class DeckRepository {
  final AppDatabase _database;

  DeckRepository(this._database);

  Future<List<Deck>> getAllDecks() => _database.getAllDecks();

  Future<List<Deck>> getDecksByFolder(int folderId) => _database.getDecksByFolder(folderId);

  Future<Deck> getDeckById(int id) => _database.getDeckById(id);

  Future<int> createDeck(DecksCompanion deck) => _database.createDeck(deck);

  Future<bool> updateDeck(Deck deck) => _database.updateDeck(deck);

  Future<bool> deleteDeck(int id) => _database.deleteDeck(id);

  Future<bool> restoreDeck(int id) => _database.restoreDeck(id);

  Future<List<Deck>> getDeletedDecks() => _database.getDeletedDecks();

  Future<void> updateDeckCardCount(int deckId) => _database.updateDeckCardCount(deckId);

  Future<List<Deck>> searchDecks(String query) => _database.searchDecks(query);
}
