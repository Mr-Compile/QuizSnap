import '../database/database.dart';
import 'package:drift/drift.dart';

class DatabaseMaintenanceService {
  final AppDatabase database;

  DatabaseMaintenanceService(this.database);

  /// Permanently removes all user-generated data while preserving the
  /// database schema, migrations, and system configuration stored outside
  /// the SQLite database (e.g. secure storage quota/PIN settings).
  Future<void> clearAllData() async {
    // Delete in an order that respects foreign key constraints.
    await database.deleteAllQuizResults();
    await database.deleteAllStudySessions();
    await database.deleteAllAiUsage();
    await database.deleteAllExtractedDocuments();
    await database.deleteAllFlashcardTags();
    await database.deleteAllFlashcards();
    await database.deleteAllDecks();
    await database.deleteAllTags();
    await database.deleteAllFolders();
  }

  Future<DatabaseIntegrityReport> checkIntegrity() async {
    final report = DatabaseIntegrityReport();

    try {
      // Check folders
      report.folderCount = await database.getAllFolders().then((list) => list.length);
      report.orphanedDecks = await _checkOrphanedDecks();
      report.orphanedFlashcards = await _checkOrphanedFlashcards();
      report.orphanedTags = await _checkOrphanedTags();
      report.orphanedFlashcardTags = await _checkOrphanedFlashcardTags();
      report.invalidReviewDates = await _checkInvalidReviewDates();
      report.invalidEaseFactors = await _checkInvalidEaseFactors();
      
      report.isHealthy = _isDatabaseHealthy(report);
    } catch (e) {
      report.error = e.toString();
      report.isHealthy = false;
    }

    return report;
  }

  Future<int> _checkOrphanedDecks() async {
    // Check for decks that reference non-existent folders
    final allDecks = await database.getAllDecks();
    final allFolders = await database.getAllFolders();
    final folderIds = allFolders.map((f) => f.id).toSet();

    int orphanCount = 0;
    for (final deck in allDecks) {
      if (deck.folderId != null && !folderIds.contains(deck.folderId)) {
        orphanCount++;
      }
    }

    return orphanCount;
  }

  Future<int> _checkOrphanedFlashcards() async {
    // Check for flashcards that reference non-existent decks
    final allFlashcards = await database.getAllFlashcards();
    final allDecks = await database.getAllDecks();
    final deckIds = allDecks.map((d) => d.id).toSet();

    return allFlashcards.where((card) => !deckIds.contains(card.deckId)).length;
  }

  Future<int> _checkOrphanedTags() async {
    // Check for tags that are not used by any flashcard
    final allTags = await database.getAllTags();
    final allFlashcardTags = await database.getAllFlashcardTags();
    final usedTagIds = allFlashcardTags.map((ft) => ft.tagId).toSet();

    return allTags.where((tag) => !usedTagIds.contains(tag.id)).length;
  }

  Future<int> _checkOrphanedFlashcardTags() async {
    // Check for flashcard tags that reference non-existent flashcards or tags
    final allFlashcardTags = await database.getAllFlashcardTags();
    final allFlashcards = await database.getAllFlashcards();
    final allTags = await database.getAllTags();
    
    final flashcardIds = allFlashcards.map((f) => f.id).toSet();
    final tagIds = allTags.map((t) => t.id).toSet();

    return allFlashcardTags.where((ft) => 
      !flashcardIds.contains(ft.flashcardId) || !tagIds.contains(ft.tagId)
    ).length;
  }

  Future<int> _checkInvalidReviewDates() async {
    // Check for flashcards with invalid review dates
    final allFlashcards = await database.getAllFlashcards();
    
    return allFlashcards.where((card) {
      if (card.nextReviewAt == null) return false;
      // Check if review date is in the past but card hasn't been reviewed
      if (card.nextReviewAt!.isBefore(DateTime.now()) && card.lastReviewedAt == null) {
        return true;
      }
      return false;
    }).length;
  }

  Future<int> _checkInvalidEaseFactors() async {
    // Check for flashcards with invalid ease factors (should be >= 1.3)
    final allFlashcards = await database.getAllFlashcards();
    
    return allFlashcards.where((card) => card.easeFactor < 1.3).length;
  }

  bool _isDatabaseHealthy(DatabaseIntegrityReport report) {
    return report.error == null &&
           report.orphanedDecks == 0 &&
           report.orphanedFlashcards == 0 &&
           report.orphanedTags == 0 &&
           report.orphanedFlashcardTags == 0 &&
           report.invalidReviewDates == 0 &&
           report.invalidEaseFactors == 0;
  }

  Future<MaintenanceResult> repairDatabase() async {
    final result = MaintenanceResult();

    try {
      // Fix orphaned decks (set folderId to null)
      final orphanedDecks = await _findOrphanedDecks();
      for (final deck in orphanedDecks) {
        await database.updateDeck(deck.copyWith(folderId: Value(null)));
        result.fixedOrphanedDecks++;
      }

      // Delete orphaned flashcards
      final orphanedFlashcards = await _findOrphanedFlashcards();
      for (final card in orphanedFlashcards) {
        await database.deleteFlashcard(card.id);
        result.deletedOrphanedFlashcards++;
      }

      // Delete orphaned tags
      final orphanedTags = await _findOrphanedTags();
      for (final tag in orphanedTags) {
        await database.deleteTag(tag.id);
        result.deletedOrphanedTags++;
      }

      // Delete orphaned flashcard tags
      final orphanedFlashcardTags = await _findOrphanedFlashcardTags();
      for (final ft in orphanedFlashcardTags) {
        await database.deleteFlashcardTag(ft.flashcardId, ft.tagId);
        result.deletedOrphanedFlashcardTags++;
      }

      // Fix invalid ease factors
      final invalidEaseCards = await _findInvalidEaseFactorCards();
      for (final card in invalidEaseCards) {
        await database.updateFlashcard(card.copyWith(easeFactor: 2.5));
        result.fixedEaseFactors++;
      }

      // Recalculate deck card counts
      final allDecks = await database.getAllDecks();
      for (final deck in allDecks) {
        await database.updateDeckCardCount(deck.id);
      }
      result.recalculatedDeckCounts = allDecks.length;

      result.success = true;
    } catch (e) {
      result.error = e.toString();
      result.success = false;
    }

    return result;
  }

  Future<List<Deck>> _findOrphanedDecks() async {
    final allDecks = await database.getAllDecks();
    final allFolders = await database.getAllFolders();
    final folderIds = allFolders.map((f) => f.id).toSet();

    return allDecks.where((deck) => 
      deck.folderId != null && !folderIds.contains(deck.folderId)
    ).toList();
  }

  Future<List<Flashcard>> _findOrphanedFlashcards() async {
    final allFlashcards = await database.getAllFlashcards();
    final allDecks = await database.getAllDecks();
    final deckIds = allDecks.map((d) => d.id).toSet();

    return allFlashcards.where((card) => !deckIds.contains(card.deckId)).toList();
  }

  Future<List<Tag>> _findOrphanedTags() async {
    final allTags = await database.getAllTags();
    final allFlashcardTags = await database.getAllFlashcardTags();
    final usedTagIds = allFlashcardTags.map((ft) => ft.tagId).toSet();

    return allTags.where((tag) => !usedTagIds.contains(tag.id)).toList();
  }

  Future<List<FlashcardTag>> _findOrphanedFlashcardTags() async {
    final allFlashcardTags = await database.getAllFlashcardTags();
    final allFlashcards = await database.getAllFlashcards();
    final allTags = await database.getAllTags();
    
    final flashcardIds = allFlashcards.map((f) => f.id).toSet();
    final tagIds = allTags.map((t) => t.id).toSet();

    return allFlashcardTags.where((ft) => 
      !flashcardIds.contains(ft.flashcardId) || !tagIds.contains(ft.tagId)
    ).toList();
  }

  Future<List<Flashcard>> _findInvalidEaseFactorCards() async {
    final allFlashcards = await database.getAllFlashcards();
    return allFlashcards.where((card) => card.easeFactor < 1.3).toList();
  }

  Future<DatabaseStats> getDatabaseStats() async {
    final stats = DatabaseStats();

    try {
      stats.folderCount = await database.getAllFolders().then((list) => list.length);
      stats.deckCount = await database.getAllDecks().then((list) => list.length);
      stats.flashcardCount = await database.getAllFlashcards().then((list) => list.length);
      stats.tagCount = await database.getAllTags().then((list) => list.length);
      stats.studySessionCount = await database.getAllStudySessions().then((list) => list.length);
      stats.quizResultCount = await database.getAllQuizResults().then((list) => list.length);
      
      // Calculate total study time
      final sessions = await database.getAllStudySessions();
      stats.totalStudyTimeSeconds = sessions.fold<int>(
        0, (sum, session) => sum + session.durationSeconds
      );
      
      // Calculate average accuracy
      final quizResults = await database.getAllQuizResults();
      if (quizResults.isNotEmpty) {
        final totalScore = quizResults.fold<double>(
          0, (sum, result) => sum + result.score
        );
        stats.averageQuizScore = totalScore / quizResults.length;
      }
    } catch (e) {
      stats.error = e.toString();
    }

    return stats;
  }

  Future<void> vacuumDatabase() async {
    // This would execute SQLite's VACUUM command to optimize the database
    // Note: This requires a custom SQL execution which may need to be added to the database
    // For now, this is a placeholder
  }
}

class DatabaseIntegrityReport {
  int folderCount = 0;
  int orphanedDecks = 0;
  int orphanedFlashcards = 0;
  int orphanedTags = 0;
  int orphanedFlashcardTags = 0;
  int invalidReviewDates = 0;
  int invalidEaseFactors = 0;
  String? error;
  bool isHealthy = true;

  @override
  String toString() {
    return 'DatabaseIntegrityReport('
        'folderCount: $folderCount, '
        'orphanedDecks: $orphanedDecks, '
        'orphanedFlashcards: $orphanedFlashcards, '
        'orphanedTags: $orphanedTags, '
        'orphanedFlashcardTags: $orphanedFlashcardTags, '
        'invalidReviewDates: $invalidReviewDates, '
        'invalidEaseFactors: $invalidEaseFactors, '
        'error: $error, '
        'isHealthy: $isHealthy)';
  }
}

class MaintenanceResult {
  bool success = false;
  int fixedOrphanedDecks = 0;
  int deletedOrphanedFlashcards = 0;
  int deletedOrphanedTags = 0;
  int deletedOrphanedFlashcardTags = 0;
  int fixedEaseFactors = 0;
  int recalculatedDeckCounts = 0;
  String? error;

  @override
  String toString() {
    return 'MaintenanceResult('
        'success: $success, '
        'fixedOrphanedDecks: $fixedOrphanedDecks, '
        'deletedOrphanedFlashcards: $deletedOrphanedFlashcards, '
        'deletedOrphanedTags: $deletedOrphanedTags, '
        'deletedOrphanedFlashcardTags: $deletedOrphanedFlashcardTags, '
        'fixedEaseFactors: $fixedEaseFactors, '
        'recalculatedDeckCounts: $recalculatedDeckCounts, '
        'error: $error)';
  }
}

class DatabaseStats {
  int folderCount = 0;
  int deckCount = 0;
  int flashcardCount = 0;
  int tagCount = 0;
  int studySessionCount = 0;
  int quizResultCount = 0;
  int totalStudyTimeSeconds = 0;
  double averageQuizScore = 0.0;
  String? error;

  String get totalStudyTimeFormatted {
    final hours = totalStudyTimeSeconds ~/ 3600;
    final minutes = (totalStudyTimeSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  String toString() {
    return 'DatabaseStats('
        'folderCount: $folderCount, '
        'deckCount: $deckCount, '
        'flashcardCount: $flashcardCount, '
        'tagCount: $tagCount, '
        'studySessionCount: $studySessionCount, '
        'quizResultCount: $quizResultCount, '
        'totalStudyTimeSeconds: $totalStudyTimeSeconds, '
        'averageQuizScore: $averageQuizScore, '
        'error: $error)';
  }
}
