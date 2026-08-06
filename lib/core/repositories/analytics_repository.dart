import '../database/database.dart';
import 'package:drift/drift.dart';

class AnalyticsRepository {
  final AppDatabase _database;

  AnalyticsRepository(this._database);

  // Get overall analytics summary
  Future<AnalyticsSummary> getAnalyticsSummary() async {
    final totalDecks = await _database.getTotalDecks();
    final totalFlashcards = await _database.getTotalFlashcards();
    final cardsStudiedToday = await _database.getCardsStudiedToday();
    final dueToday = await _database.getDueTodayCount();
    final currentStreak = await _database.getCurrentStreak();
    final averageQuizScore = await _database.getAverageQuizScore();

    return AnalyticsSummary(
      totalDecks: totalDecks,
      totalFlashcards: totalFlashcards,
      cardsStudiedToday: cardsStudiedToday,
      dueToday: dueToday,
      currentStreak: currentStreak,
      averageQuizScore: averageQuizScore,
    );
  }

  // Get daily study activity for charts
  Future<List<DailyStudyActivity>> getDailyStudyActivity({int days = 30}) {
    return _database.getDailyStudyActivity(days);
  }

  // Get mastery distribution
  Future<List<MasteryDistribution>> getMasteryDistribution() {
    return _database.getMasteryDistribution();
  }

  // Get accuracy by deck (for weak topics)
  Future<List<DeckAccuracy>> getAccuracyByDeck() {
    return _database.getAccuracyByDeck();
  }

  // Get recent study sessions
  Future<List<StudySession>> getRecentStudySessions({int limit = 10}) {
    return _database.getRecentStudySessions(limit);
  }

  // Get recent quiz results
  Future<List<QuizResult>> getRecentQuizResults({int limit = 10}) {
    return _database.getRecentQuizResults(limit);
  }

  // Create a study session
  Future<int> startStudySession({
    int? deckId,
    String studyMode = 'review',
  }) {
    return _database.createStudySession(StudySessionsCompanion(
      deckId: deckId != null ? Value(deckId) : const Value.absent(),
      studyMode: Value(studyMode),
      startedAt: Value(DateTime.now()),
    ));
  }

  // End a study session
  Future<void> endStudySession(int sessionId, {
    required int cardsStudied,
    required int cardsCorrect,
    required int durationSeconds,
  }) async {
    final session = await (_database.select(_database.studySessions)
      ..where((tbl) => tbl.id.equals(sessionId)))
      .getSingle();

    await _database.updateStudySession(session.copyWith(
      cardsStudied: cardsStudied,
      cardsCorrect: cardsCorrect,
      durationSeconds: durationSeconds,
      endedAt: Value(DateTime.now()),
    ));
  }

  // Create a quiz result
  Future<int> createQuizResult({
    int? deckId,
    required int totalQuestions,
    required int correctAnswers,
    required double score,
    required int durationSeconds,
    String quizType = 'practice',
  }) {
    return _database.createQuizResult(QuizResultsCompanion(
      deckId: deckId != null ? Value(deckId) : const Value.absent(),
      totalQuestions: Value(totalQuestions),
      correctAnswers: Value(correctAnswers),
      score: Value(score),
      durationSeconds: Value(durationSeconds),
      quizType: Value(quizType),
      completedAt: Value(DateTime.now()),
    ));
  }

  // Get study time statistics
  Future<StudyTimeStats> getStudyTimeStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    final todaySessions = await _database.select(_database.studySessions)
      ..where((tbl) => tbl.startedAt.isBiggerOrEqualValue(startOfDay))
      ..get();

    final weekSessions = await _database.select(_database.studySessions)
      ..where((tbl) => tbl.startedAt.isBiggerOrEqualValue(startOfWeekDay))
      ..get();

    final monthSessions = await _database.select(_database.studySessions)
      ..where((tbl) => tbl.startedAt.isBiggerOrEqualValue(startOfMonth))
      ..get();

    final todayMinutes = todaySessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;
    final weekMinutes = weekSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;
    final monthMinutes = monthSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;

    return StudyTimeStats(
      todayMinutes: todayMinutes,
      weekMinutes: weekMinutes,
      monthMinutes: monthMinutes,
      todaySessions: todaySessions.length,
      weekSessions: weekSessions.length,
      monthSessions: monthSessions.length,
    );
  }

  // Get improvement trends
  Future<ImprovementTrends> getImprovementTrends() async {
    final now = DateTime.now();
    const periodDays = 30;
    final startDate = now.subtract(const Duration(days: periodDays));
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);

    final recentSessions = await _database.select(_database.studySessions)
      ..where((tbl) => tbl.startedAt.isBiggerOrEqualValue(startOfDay))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.startedAt)])
      ..get();

    if (recentSessions.isEmpty) {
      return ImprovementTrends(
        periodDays: periodDays,
        averageAccuracy: 0.0,
        averageCardsPerSession: 0.0,
        totalStudyTimeMinutes: 0,
        trend: 'stable',
      );
    }

    final totalAccuracy = recentSessions.fold<double>(0, (sum, s) {
      if (s.cardsStudied == 0) return sum;
      return sum + (s.cardsCorrect / s.cardsStudied * 100);
    }) / recentSessions.length;

    final averageCardsPerSession = recentSessions.fold<int>(0, (sum, s) => sum + s.cardsStudied) / recentSessions.length;
    final totalStudyTimeMinutes = recentSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;

    // Calculate trend
    final midPoint = recentSessions.length ~/ 2;
    final firstHalf = recentSessions.sublist(0, midPoint);
    final secondHalf = recentSessions.sublist(midPoint);

    final firstHalfAccuracy = firstHalf.isEmpty ? 0.0 : firstHalf.fold<double>(0, (sum, s) {
      if (s.cardsStudied == 0) return sum;
      return sum + (s.cardsCorrect / s.cardsStudied * 100);
    }) / firstHalf.length;

    final secondHalfAccuracy = secondHalf.isEmpty ? 0.0 : secondHalf.fold<double>(0, (sum, s) {
      if (s.cardsStudied == 0) return sum;
      return sum + (s.cardsCorrect / s.cardsStudied * 100);
    }) / secondHalf.length;

    String trend;
    if (secondHalfAccuracy > firstHalfAccuracy + 5) {
      trend = 'improving';
    } else if (secondHalfAccuracy < firstHalfAccuracy - 5) {
      trend = 'declining';
    } else {
      trend = 'stable';
    }

    return ImprovementTrends(
      periodDays: periodDays,
      averageAccuracy: totalAccuracy,
      averageCardsPerSession: averageCardsPerSession,
      totalStudyTimeMinutes: totalStudyTimeMinutes,
      trend: trend,
    );
  }
}

// Analytics data models
class AnalyticsSummary {
  final int totalDecks;
  final int totalFlashcards;
  final int cardsStudiedToday;
  final int dueToday;
  final int currentStreak;
  final double averageQuizScore;

  AnalyticsSummary({
    required this.totalDecks,
    required this.totalFlashcards,
    required this.cardsStudiedToday,
    required this.dueToday,
    required this.currentStreak,
    required this.averageQuizScore,
  });
}

class StudyTimeStats {
  final int todayMinutes;
  final int weekMinutes;
  final int monthMinutes;
  final int todaySessions;
  final int weekSessions;
  final int monthSessions;

  StudyTimeStats({
    required this.todayMinutes,
    required this.weekMinutes,
    required this.monthMinutes,
    required this.todaySessions,
    required this.weekSessions,
    required this.monthSessions,
  });
}

class ImprovementTrends {
  final int periodDays;
  final double averageAccuracy;
  final double averageCardsPerSession;
  final int totalStudyTimeMinutes;
  final String trend; // 'improving', 'declining', 'stable'

  ImprovementTrends({
    required this.periodDays,
    required this.averageAccuracy,
    required this.averageCardsPerSession,
    required this.totalStudyTimeMinutes,
    required this.trend,
  });
}