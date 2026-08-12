import 'package:flutter/foundation.dart';

/// Lightweight provider that tracks whether the current flashcard's answer
/// is revealed. Used by the flashcard study engine.
class FlashcardRevealProvider with ChangeNotifier {
  final Set<int> _revealedCardIds = {};

  bool isRevealed(int flashcardId) => _revealedCardIds.contains(flashcardId);

  void reveal(int flashcardId) {
    if (_revealedCardIds.add(flashcardId)) {
      notifyListeners();
    }
  }

  void hide(int flashcardId) {
    if (_revealedCardIds.remove(flashcardId)) {
      notifyListeners();
    }
  }

  void toggle(int flashcardId) {
    if (_revealedCardIds.contains(flashcardId)) {
      hide(flashcardId);
    } else {
      reveal(flashcardId);
    }
  }

  void clear() {
    if (_revealedCardIds.isNotEmpty) {
      _revealedCardIds.clear();
      notifyListeners();
    }
  }
}
