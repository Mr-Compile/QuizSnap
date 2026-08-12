import 'package:flutter/material.dart';
import '../repositories/flashcard_repository.dart';

/// Coordinates moving one or more flashcards to a different deck.
///
/// This is a short-lived provider used by the move workflow. It does not
/// manage global state; callers provide a [FlashcardRepository] instance.
class MoveFlashcardProvider with ChangeNotifier {
  final FlashcardRepository _flashcardRepository;
  bool _isMoving = false;
  String? _error;

  MoveFlashcardProvider(this._flashcardRepository);

  bool get isMoving => _isMoving;
  String? get error => _error;

  Future<bool> moveFlashcards(List<int> flashcardIds, int newDeckId) async {
    _isMoving = true;
    _error = null;
    notifyListeners();

    try {
      for (final id in flashcardIds) {
        await _flashcardRepository.moveFlashcard(id, newDeckId);
      }
      _isMoving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isMoving = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
