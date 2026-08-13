import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/database/database.dart';
import '../../core/services/study_session_persistence.dart';

/// Controller for a flashcard study session.
///
/// Tracks progress, reveals, ratings, time spent, bookmarks and supports resume.
class StudySessionController with ChangeNotifier {
  final StudySessionPersistence? _persistence;

  StudySessionPersistence? get persistence => _persistence;

  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;
  int _deckId = 0;
  String _deckName = '';
  final Set<int> _ratedCardIds = {};
  final Map<int, int> _cardRatings = {};
  final Set<int> _revealedCardIds = {};
  DateTime? _sessionStart;

  StudySessionController({this._persistence});

  // Getters
  bool get hasCards => _flashcards.isNotEmpty;
  int get currentIndex => _currentIndex;
  int get totalCards => _flashcards.length;
  int get deckId => _deckId;
  String get deckName => _deckName;
  Flashcard? get currentCard => _flashcards.isEmpty || _currentIndex >= _flashcards.length
      ? null
      : _flashcards[_currentIndex];
  bool get isRevealed => currentCard != null && _revealedCardIds.contains(currentCard!.id);
  bool get isLastCard => _flashcards.isEmpty || _currentIndex >= _flashcards.length - 1;
  bool get isComplete => _flashcards.isNotEmpty && _currentIndex >= _flashcards.length;
  double get progress => _flashcards.isEmpty ? 0.0 : (_currentIndex + 1) / _flashcards.length;

  Set<int> get revealedCardIds => _revealedCardIds;
  Set<int> get ratedCardIds => _ratedCardIds;
  Map<int, int> get cardRatings => _cardRatings;

  Duration get timeSpent => _sessionStart != null
      ? DateTime.now().difference(_sessionStart!)
      : Duration.zero;

  double get averageConfidence {
    if (_cardRatings.isEmpty) return 0.0;
    return _cardRatings.values.reduce((a, b) => a + b) / _cardRatings.length;
  }

  StudySessionState get currentState => StudySessionState(
        deckId: _deckId,
        deckName: _deckName,
        currentIndex: _currentIndex,
        isRevealed: isRevealed,
        totalCards: _flashcards.length,
        lastStudiedAt: DateTime.now(),
      );

  SessionSummary get sessionSummary => SessionSummary(
        cardsStudied: _cardRatings.length,
        totalCards: _flashcards.length,
        averageConfidence: averageConfidence,
        timeSpent: timeSpent,
        dueTomorrowCount: _flashcards.where(_isDueTomorrow).length,
      );

  void startSession({
    required List<Flashcard> flashcards,
    required int deckId,
    required String deckName,
    int startIndex = 0,
    bool startRevealed = false,
    bool shuffle = false,
  }) {
    final source = List<Flashcard>.from(flashcards);
    _flashcards = List.unmodifiable(shuffle ? _shuffleList(source) : source);
    _deckId = deckId;
    _deckName = deckName;
    _currentIndex = startIndex.clamp(0, max(0, _flashcards.length - 1));
    _ratedCardIds.clear();
    _cardRatings.clear();
    _revealedCardIds.clear();
    _sessionStart = DateTime.now();
    if (startRevealed && currentCard != null) {
      _revealedCardIds.add(currentCard!.id);
    }
    _persist();
    notifyListeners();
  }

  List<T> _shuffleList<T>(List<T> list) {
    final shuffled = List<T>.from(list);
    final random = Random();
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled;
  }

  void resumeSession({
    required List<Flashcard> flashcards,
    required StudySessionState state,
  }) {
    startSession(
      flashcards: flashcards,
      deckId: state.deckId,
      deckName: state.deckName,
      startIndex: state.currentIndex,
      startRevealed: state.isRevealed,
    );
  }

  void revealCurrentCard() {
    final card = currentCard;
    if (card != null && _revealedCardIds.add(card.id)) {
      HapticFeedback.lightImpact();
      _persist();
      notifyListeners();
    }
  }

  void hideCurrentCard() {
    final card = currentCard;
    if (card != null && _revealedCardIds.remove(card.id)) {
      _persist();
      notifyListeners();
    }
  }

  void toggleReveal() {
    if (isRevealed) {
      hideCurrentCard();
    } else {
      revealCurrentCard();
    }
  }

  void nextCard() {
    if (_currentIndex < _flashcards.length - 1) {
      _currentIndex++;
      _persist();
      notifyListeners();
    } else if (_currentIndex < _flashcards.length) {
      _currentIndex++;
      _persist();
      notifyListeners();
    }
  }

  void previousCard() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _persist();
      notifyListeners();
    }
  }

  void goToCard(int index) {
    _currentIndex = index.clamp(0, _flashcards.length - 1);
    _persist();
    notifyListeners();
  }

  Future<void> rateCurrentCard({
    required int quality,
    required Future<void> Function(int, int) onPersist,
  }) async {
    final card = currentCard;
    if (card == null) return;

    _ratedCardIds.add(card.id);
    _cardRatings[card.id] = quality;
    await onPersist(card.id, quality);
    _persist();
    notifyListeners();
  }

  /// Rates the card and immediately moves to the next card.
  Future<void> rateAndAdvance({
    required int quality,
    required Future<void> Function(int, int) onPersist,
  }) async {
    await rateCurrentCard(quality: quality, onPersist: onPersist);
    if (!isComplete) {
      nextCard();
    }
  }

  bool hasRating(int flashcardId) => _ratedCardIds.contains(flashcardId);
  int? getRating(int flashcardId) => _cardRatings[flashcardId];

  void endSession() {
    _persistence?.clear();
    _sessionStart = null;
  }

  void _persist() {
    if (_persistence == null) return;
    _persistence.save(currentState);
  }

  bool _isDueTomorrow(Flashcard card) {
    if (card.nextReviewAt == null) return false;
    final next = card.nextReviewAt!;
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return next.isBefore(tomorrow) && next.isAfter(now);
  }

  Map<String, dynamic> toSnapshot() {
    return {
      'deckName': _deckName,
      'currentIndex': _currentIndex,
      'ratedCardIds': _ratedCardIds.toList(),
      'cardRatings': _cardRatings,
      'revealedCardIds': _revealedCardIds.toList(),
    };
  }
}

class SessionSummary {
  final int cardsStudied;
  final int totalCards;
  final double averageConfidence;
  final Duration timeSpent;
  final int dueTomorrowCount;

  SessionSummary({
    required this.cardsStudied,
    required this.totalCards,
    required this.averageConfidence,
    required this.timeSpent,
    required this.dueTomorrowCount,
  });
}
