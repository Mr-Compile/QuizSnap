import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../services/trash_service.dart';

/// View-level provider for the Trash screen.
///
/// Loads deleted decks and flashcards and exposes bulk restore/empty
/// operations with loading and error states.
class TrashProvider with ChangeNotifier {
  final TrashService _trashService;

  bool _isLoading = false;
  String? _error;
  List<Deck> _deletedDecks = [];
  List<Flashcard> _deletedFlashcards = [];

  TrashProvider(this._trashService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Deck> get deletedDecks => _deletedDecks;
  List<Flashcard> get deletedFlashcards => _deletedFlashcards;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _deletedDecks = await _trashService.getDeletedDecks();
      _deletedFlashcards = await _trashService.getDeletedFlashcards();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreDeck(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _trashService.restoreDeck(id);
      await load();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreFlashcard(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _trashService.restoreFlashcard(id);
      await load();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> permanentlyDeleteDeck(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _trashService.permanentlyDeleteDeck(id);
      await load();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> permanentlyDeleteFlashcard(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _trashService.permanentlyDeleteFlashcard(id);
      await load();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> emptyTrash() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _trashService.emptyTrash();
      _deletedDecks = [];
      _deletedFlashcards = [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _trashService.restoreAll();
      _deletedDecks = [];
      _deletedFlashcards = [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
