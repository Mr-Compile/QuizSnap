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

  // Crash-safe study-time tracking.
  // [_accumulatedSeconds] holds time persisted across pauses/backgrounding.
  // [_activeSince] marks the start of the current active (non-paused) span.
  // [_isPaused] is true while the app is inactive/backgrounded.
  int _accumulatedSeconds = 0;
  DateTime? _activeSince;
  bool _isPaused = false;

  // Total review interactions (reveal + rate events). May exceed the unique
  // reviewed-card count because a single card can be interacted with多次.
  int _totalReviewInteractions = 0;

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

  /// Unique set of cards that count as "studied" this session: any card that
  /// was revealed, rated, or otherwise reviewed. Loaded/skipped cards are NOT
  /// included.
  Set<int> get reviewedCardIds => {..._revealedCardIds, ..._ratedCardIds};

  /// Unique count of cards studied this session.
  int get cardsStudied => reviewedCardIds.length;

  /// Total review interactions (reveal + rate events) this session. Can exceed
  /// [cardsStudied] because the same card may be interacted with多次.
  int get totalReviews => _totalReviewInteractions;

  /// Accumulated study seconds persisted across pauses/backgrounding.
  int get accumulatedSeconds => _accumulatedSeconds;

  /// Whether the session timer is currently paused (app inactive/backgrounded).
  bool get isPaused => _isPaused;

  /// Live elapsed seconds = persisted accumulation + current active span.
  int get elapsedSeconds {
    final active = _activeSince != null && !_isPaused
        ? DateTime.now().difference(_activeSince!).inSeconds
        : 0;
    return _accumulatedSeconds + active;
  }

  Duration get timeSpent => Duration(seconds: elapsedSeconds);

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
        accumulatedSeconds: snapshotSeconds(),
        lastStudiedAt: DateTime.now(),
      );

  SessionSummary get sessionSummary => SessionSummary(
        cardsStudied: cardsStudied,
        totalReviews: totalReviews,
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
    int resumeAccumulatedSeconds = 0,
  }) {
    final source = List<Flashcard>.from(flashcards);
    _flashcards = List.unmodifiable(shuffle ? _shuffleList(source) : source);
    _deckId = deckId;
    _deckName = deckName;
    _currentIndex = startIndex.clamp(0, max(0, _flashcards.length - 1));
    _ratedCardIds.clear();
    _cardRatings.clear();
    _revealedCardIds.clear();
    _totalReviewInteractions = 0;
    _accumulatedSeconds = resumeAccumulatedSeconds;
    _isPaused = false;
    _activeSince = DateTime.now();
    if (startRevealed && currentCard != null) {
      _revealedCardIds.add(currentCard!.id);
      _totalReviewInteractions++;
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
      resumeAccumulatedSeconds: state.accumulatedSeconds,
    );
  }

  void revealCurrentCard() {
    final card = currentCard;
    if (card != null && _revealedCardIds.add(card.id)) {
      _totalReviewInteractions++;
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
    _totalReviewInteractions++;
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

  /// Pauses the live timer and folds the current active span into the
  /// accumulated seconds. Safe to call repeatedly. Returns the accumulated
  /// seconds so the caller can persist them to the database.
  int pause() {
    if (_isPaused) return _accumulatedSeconds;
    _foldActiveSpan();
    _isPaused = true;
    _activeSince = null;
    notifyListeners();
    return _accumulatedSeconds;
  }

  /// Resumes the live timer starting a new active span. Does not double-count
  /// because [pause] already folded the previous span into accumulation.
  void resume() {
    if (!_isPaused) {
      // Ensure an active span exists even if resume is called without pause.
      _activeSince ??= DateTime.now();
      return;
    }
    _isPaused = false;
    _activeSince = DateTime.now();
    notifyListeners();
  }

  /// Folds the current active span (if any) into [_accumulatedSeconds].
  void _foldActiveSpan() {
    if (_activeSince != null) {
      _accumulatedSeconds += DateTime.now().difference(_activeSince!).inSeconds;
      _activeSince = null;
    }
  }

  /// Returns the accumulated seconds after folding the current active span,
  /// without changing the paused state. Used for periodic persistence so the
  /// DB always reflects the latest study time without ending the session.
  int snapshotSeconds() {
    final active = _activeSince != null && !_isPaused
        ? DateTime.now().difference(_activeSince!).inSeconds
        : 0;
    return _accumulatedSeconds + active;
  }

  void endSession() {
    _foldActiveSpan();
    _persistence?.clear();
    _activeSince = null;
    _isPaused = false;
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
  final int totalReviews;
  final int totalCards;
  final double averageConfidence;
  final Duration timeSpent;
  final int dueTomorrowCount;

  SessionSummary({
    required this.cardsStudied,
    required this.totalReviews,
    required this.totalCards,
    required this.averageConfidence,
    required this.timeSpent,
    required this.dueTomorrowCount,
  });
}
