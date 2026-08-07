import '../database/database.dart';
import 'package:drift/drift.dart';

class StudyRepository {
  final AppDatabase _database;

  StudyRepository(this._database);

  // Get cards due for review today
  Future<List<Flashcard>> getDueFlashcards() => _database.getFlashcardsDueForReview();

  // Get favorite/bookmarked cards
  Future<List<Flashcard>> getBookmarkedFlashcards() => _database.getFavoriteFlashcards();

  // Get all cards for a deck (for study modes)
  Future<List<Flashcard>> getFlashcardsByDeck(int deckId) => _database.getFlashcardsByDeck(deckId);

  // Update card using SM-2 algorithm
  Future<void> updateCardReview(int id, int quality) => _database.updateFlashcardReviewSM2(id, quality);

  // Toggle bookmark status
  Future<void> toggleBookmark(int id) async {
    final flashcard = await _database.getFlashcardById(id);
    await _database.updateFlashcard(flashcard.copyWith(isFavorite: !flashcard.isFavorite));
  }

  // Get study statistics
  Future<StudyStats> getStudyStats() async {
    final dueCards = await getDueFlashcards();
    final bookmarkedCards = await getBookmarkedFlashcards();
    final allCards = await _database.getAllFlashcards();
    
    int totalReviews = 0;
    int totalCorrect = 0;
    
    for (final card in allCards) {
      totalReviews += card.reviewCount;
      totalCorrect += card.correctCount;
    }
    
    return StudyStats(
      dueToday: dueCards.length,
      bookmarked: bookmarkedCards.length,
      totalCards: allCards.length,
      totalReviews: totalReviews,
      accuracy: totalReviews > 0 ? (totalCorrect / totalReviews * 100).round() : 0,
    );
  }

  // Get cards due in next 7 days
  Future<List<Flashcard>> getUpcomingReviews() async {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    
    return (_database.select(_database.flashcards)
      ..where((tbl) => tbl.nextReviewAt.isBiggerOrEqualValue(now))
      ..where((tbl) => tbl.nextReviewAt.isSmallerOrEqualValue(weekFromNow))
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.nextReviewAt)]))
      .get();
  }
}

class StudyStats {
  final int dueToday;
  final int bookmarked;
  final int totalCards;
  final int totalReviews;
  final int accuracy;

  StudyStats({
    required this.dueToday,
    required this.bookmarked,
    required this.totalCards,
    required this.totalReviews,
    required this.accuracy,
  });
}