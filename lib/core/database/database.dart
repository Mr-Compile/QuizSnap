import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'dart:io';

part 'database.g.dart';

class Folders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().withDefault(const Constant('#4CAF50'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class Decks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  IntColumn get folderId => integer().nullable().references(Folders, #id)();
  TextColumn get color => text().withDefault(const Constant('#4CAF50'))();
  IntColumn get cardCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class Flashcards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get question => text().withLength(min: 1)();
  TextColumn get answer => text().withLength(min: 1)();
  IntColumn get deckId => integer().references(Decks, #id)();
  IntColumn get order => integer().withDefault(const Constant(0))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  // SM-2 Algorithm fields
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get interval => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get color => text().withDefault(const Constant('#4CAF50'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class FlashcardTags extends Table {
  IntColumn get flashcardId => integer().references(Flashcards, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
  
  @override
  Set<Column> get primaryKey => {flashcardId, tagId};
}

class StudySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deckId => integer().nullable().references(Decks, #id)();
  IntColumn get cardsStudied => integer().withDefault(const Constant(0))();
  IntColumn get cardsCorrect => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  TextColumn get studyMode => text().withDefault(const Constant('review'))(); // 'review', 'quiz', 'flashcard'
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class QuizResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deckId => integer().nullable().references(Decks, #id)();
  IntColumn get totalQuestions => integer().withDefault(const Constant(0))();
  IntColumn get correctAnswers => integer().withDefault(const Constant(0))();
  RealColumn get score => real().withDefault(const Constant(0.0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  TextColumn get quizType => text().withDefault(const Constant('practice'))(); // 'practice', 'exam'
  DateTimeColumn get completedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Folders, Decks, Flashcards, Tags, FlashcardTags, StudySessions, QuizResults])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1 && to == 2) {
          // Add SM-2 algorithm fields
          await m.addColumn(flashcards, flashcards.easeFactor);
          await m.addColumn(flashcards, flashcards.interval);
          await m.addColumn(flashcards, flashcards.repetitions);
        }
        if (from == 2 && to == 3) {
          // Add analytics tables
          await m.createTable(studySessions);
          await m.createTable(quizResults);
        }
      },
    );
  }

  // Folder Queries
  Future<List<Folder>> getAllFolders() => (select(folders)
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
      .get();

  Future<Folder> getFolderById(int id) => (select(folders)
        ..where((tbl) => tbl.id.equals(id))
        ..where((tbl) => tbl.deletedAt.isNull()))
      .getSingle();

  Future<int> createFolder(FoldersCompanion folder) => into(folders).insert(folder);

  Future<bool> updateFolder(Folder folder) => update(folders).replace(folder);

  Future<void> deleteFolder(int id) async {
    final folder = await getFolderById(id);
    final updatedFolder = folder.copyWith(deletedAt: Value(DateTime.now()));
    await update(folders).replace(updatedFolder);
  }

  Future<void> restoreFolder(int id) async {
    final folder = await getFolderById(id);
    final updatedFolder = folder.copyWith(deletedAt: const Value(null));
    await update(folders).replace(updatedFolder);
  }

  Future<List<Folder>> getDeletedFolders() => (select(folders)
      ..where((tbl) => tbl.deletedAt.isNotNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.deletedAt)]))
    .get();

  void permanentlyDeleteFolder(int id) {
    // ignore: use_of_void_result
    delete(folders).where((tbl) => tbl.id.equals(id)).go();
  }

  // Deck Queries
  Future<List<Deck>> getAllDecks() => (select(decks)
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
      .get();

  Future<List<Deck>> getDecksByFolder(int folderId) => (select(decks)
        ..where((tbl) => tbl.folderId.equals(folderId))
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
      .get();

  Future<Deck> getDeckById(int id) => (select(decks)
        ..where((tbl) => tbl.id.equals(id))
        ..where((tbl) => tbl.deletedAt.isNull()))
      .getSingle();

  Future<int> createDeck(DecksCompanion deck) => into(decks).insert(deck);

  Future<bool> updateDeck(Deck deck) => update(decks).replace(deck);

  Future<void> deleteDeck(int id) async {
    final deck = await getDeckById(id);
    final updatedDeck = deck.copyWith(deletedAt: Value(DateTime.now()));
    await update(decks).replace(updatedDeck);
  }

  Future<void> restoreDeck(int id) async {
    final deck = await getDeckById(id);
    final updatedDeck = deck.copyWith(deletedAt: const Value(null));
    await update(decks).replace(updatedDeck);
  }

  Future<List<Deck>> getDeletedDecks() => (select(decks)
      ..where((tbl) => tbl.deletedAt.isNotNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.deletedAt)]))
    .get();

  void permanentlyDeleteDeck(int id) {
    // ignore: use_of_void_result
    delete(decks).where((tbl) => tbl.id.equals(id)).go();
  }

  Future<int> updateDeckCardCount(int deckId) async {
    final cards = await (select(flashcards)
          ..where((tbl) => tbl.deckId.equals(deckId))
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();
    final count = cards.length;

    final deck = await getDeckById(deckId);
    final updatedDeck = deck.copyWith(cardCount: count);
    await update(decks).replace(updatedDeck);
    
    return count;
  }

  // Flashcard Queries
  Future<List<Flashcard>> getAllFlashcards() => (select(flashcards)
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.order)]))
    .get();

  Future<List<Flashcard>> getFlashcardsByDeck(int deckId) => (select(flashcards)
        ..where((tbl) => tbl.deckId.equals(deckId))
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.order)]))
      .get();

  Future<Flashcard> getFlashcardById(int id) => (select(flashcards)
        ..where((tbl) => tbl.id.equals(id))
        ..where((tbl) => tbl.deletedAt.isNull()))
      .getSingle();

  Future<int> createFlashcard(FlashcardsCompanion flashcard) =>
      into(flashcards).insert(flashcard);

  Future<bool> updateFlashcard(Flashcard flashcard) =>
      update(flashcards).replace(flashcard);

  Future<void> deleteFlashcard(int id) async {
    final flashcard = await getFlashcardById(id);
    final updatedFlashcard = flashcard.copyWith(deletedAt: Value(DateTime.now()));
    await update(flashcards).replace(updatedFlashcard);
  }

  Future<void> restoreFlashcard(int id) async {
    final flashcard = await getFlashcardById(id);
    final updatedFlashcard = flashcard.copyWith(deletedAt: const Value(null));
    await update(flashcards).replace(updatedFlashcard);
  }

  Future<List<Flashcard>> getDeletedFlashcards() => (select(flashcards)
      ..where((tbl) => tbl.deletedAt.isNotNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.deletedAt)]))
    .get();

  void permanentlyDeleteFlashcard(int id) {
    // ignore: use_of_void_result
    delete(flashcards).where((tbl) => tbl.id.equals(id)).go();
  }

  Future<List<Flashcard>> getFavoriteFlashcards() => (select(flashcards)
      ..where((tbl) => tbl.isFavorite.equals(true))
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastReviewedAt)]))
    .get();

  Future<List<Flashcard>> getFlashcardsDueForReview() => (select(flashcards)
      ..where((tbl) => tbl.nextReviewAt.isSmallerThanValue(DateTime.now()))
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.nextReviewAt)]))
    .get();

  Future<void> updateFlashcardReview(int id, bool correct) async {
    final flashcard = await getFlashcardById(id);
    final newReviewCount = flashcard.reviewCount + 1;
    final newCorrectCount = correct ? flashcard.correctCount + 1 : flashcard.correctCount;
    
    // Simple spaced repetition algorithm (backward compatible)
    final now = DateTime.now();
    DateTime? nextReview;
    if (correct) {
      final interval = _calculateReviewInterval(newCorrectCount, newReviewCount);
      nextReview = now.add(Duration(days: interval));
    } else {
      nextReview = now.add(const Duration(days: 1));
    }

    await (update(flashcards)..where((tbl) => tbl.id.equals(id)))
        .write(FlashcardsCompanion(
          reviewCount: Value(newReviewCount),
          correctCount: Value(newCorrectCount),
          lastReviewedAt: Value(now),
          nextReviewAt: Value(nextReview),
        ));
  }

  // SM-2 Algorithm implementation
  Future<void> updateFlashcardReviewSM2(int id, int quality) async {
    // Quality: 0-5 (0=blackout, 1=incorrect, 2=hard, 3=good, 4=easy, 5=perfect)
    final flashcard = await getFlashcardById(id);
    final now = DateTime.now();
    
    double easeFactor = flashcard.easeFactor;
    int interval = flashcard.interval;
    int repetitions = flashcard.repetitions;
    
    if (quality >= 3) {
      // Correct response
      if (repetitions == 0) {
        interval = 1;
      } else if (repetitions == 1) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
      repetitions++;
    } else {
      // Incorrect response - reset
      repetitions = 0;
      interval = 1;
    }
    
    // Update ease factor
    easeFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (easeFactor < 1.3) easeFactor = 1.3;
    
    final nextReview = now.add(Duration(days: interval));
    
    await (update(flashcards)..where((tbl) => tbl.id.equals(id)))
        .write(FlashcardsCompanion(
          reviewCount: Value(flashcard.reviewCount + 1),
          correctCount: Value(quality >= 3 ? flashcard.correctCount + 1 : flashcard.correctCount),
          lastReviewedAt: Value(now),
          nextReviewAt: Value(nextReview),
          easeFactor: Value(easeFactor),
          interval: Value(interval),
          repetitions: Value(repetitions),
        ));
  }

  int _calculateReviewInterval(int correctCount, int reviewCount) {
    if (reviewCount == 1) return 1;
    if (reviewCount == 2) return 3;
    if (reviewCount == 3) return 7;
    if (reviewCount == 4) return 14;
    if (reviewCount == 5) return 30;
    
    final accuracy = correctCount / reviewCount;
    if (accuracy > 0.8) return 60;
    if (accuracy > 0.6) return 30;
    return 14;
  }

  // Tag Queries
  Future<List<Tag>> getAllTags() => (select(tags)
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
      .get();

  Future<Tag> getTagById(int id) => (select(tags)
        ..where((tbl) => tbl.id.equals(id)))
      .getSingle();

  Future<int> createTag(TagsCompanion tag) => into(tags).insert(tag);

  Future<bool> updateTag(Tag tag) => update(tags).replace(tag);

  void deleteTag(int id) {
    // ignore: use_of_void_result
    delete(tags).where((tbl) => tbl.id.equals(id)).go();
  }

  // Flashcard Tag Queries
  Future<List<Tag>> getTagsForFlashcard(int flashcardId) {
    final query = select(tags).join([
      innerJoin(
        flashcardTags,
        flashcardTags.tagId.equalsExp(tags.id),
      ),
    ])
      ..where(flashcardTags.flashcardId.equals(flashcardId))
      ..orderBy([OrderingTerm.asc(tags.name)]);

    return query.map((row) => row.readTable(tags)).get();
  }

  Future<int> addTagToFlashcard(int flashcardId, int tagId) =>
      into(flashcardTags).insert(FlashcardTagsCompanion(
            flashcardId: Value(flashcardId),
            tagId: Value(tagId),
          ), mode: InsertMode.insertOrIgnore);

  void removeTagFromFlashcard(int flashcardId, int tagId) {
    // ignore: use_of_void_result
    (delete(flashcardTags)
        ..where((tbl) => tbl.flashcardId.equals(flashcardId))
        ..where((tbl) => tbl.tagId.equals(tagId)))
      .go();
  }

  Future<void> setFlashcardTags(int flashcardId, List<int> tagIds) async {
    // ignore: use_of_void_result
    delete(flashcardTags)
        .where((tbl) => tbl.flashcardId.equals(flashcardId))
        .go();
    
    for (final tagId in tagIds) {
      await addTagToFlashcard(flashcardId, tagId);
    }
  }

  Future<List<FlashcardTag>> getAllFlashcardTags() => select(flashcardTags).get();

  Future<int> createFlashcardTag(FlashcardTagsCompanion flashcardTag) =>
      into(flashcardTags).insert(flashcardTag);

  Future<int> deleteFlashcardTag(int flashcardId, int tagId) =>
      (delete(flashcardTags)
          ..where((tbl) => tbl.flashcardId.equals(flashcardId))
          ..where((tbl) => tbl.tagId.equals(tagId)))
        .go();

  Future<List<StudySession>> getAllStudySessions() => (select(studySessions)).get();

  Future<List<QuizResult>> getAllQuizResults() => (select(quizResults)).get();

  Future<int> createStudySession(StudySessionsCompanion session) =>
      into(studySessions).insert(session);

  // Delete all methods for backup restore
  Future<int> deleteAllQuizResults() => (delete(quizResults)).go();
  Future<int> deleteAllStudySessions() => (delete(studySessions)).go();
  Future<int> deleteAllFlashcardTags() => (delete(flashcardTags)).go();
  Future<int> deleteAllFlashcards() => (delete(flashcards)).go();
  Future<int> deleteAllDecks() => (delete(decks)).go();
  Future<int> deleteAllTags() => (delete(tags)).go();
  Future<int> deleteAllFolders() => (delete(folders)).go();

  // Search Queries
  Future<List<Flashcard>> searchFlashcards(String query) {
    final searchTerm = '%$query%';
    return (select(flashcards)
        ..where((tbl) => tbl.question.like(searchTerm) |
            tbl.answer.like(searchTerm))
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.order)]))
      .get();
  }

  Future<List<Deck>> searchDecks(String query) {
    final searchTerm = '%$query%';
    return (select(decks)
        ..where((tbl) => tbl.name.like(searchTerm) |
            (tbl.description.like(searchTerm)))
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
      .get();
  }

  Future<List<Folder>> searchFolders(String query) {
    final searchTerm = '%$query%';
    return (select(folders)
        ..where((tbl) => tbl.name.like(searchTerm) |
            (tbl.description.like(searchTerm)))
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
      .get();
  }

  // Study Session Queries
  Future<bool> updateStudySession(StudySession session) =>
      update(studySessions).replace(session);

  Future<List<StudySession>> getStudySessionsByDeck(int deckId) => (select(studySessions)
        ..where((tbl) => tbl.deckId.equals(deckId))
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)]))
      .get();

  Future<List<StudySession>> getRecentStudySessions(int limit) => (select(studySessions)
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)])
        ..limit(limit))
      .get();

  Future<List<StudySession>> getTodayStudySessions() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return (select(studySessions)
        ..where((tbl) => tbl.startedAt.isBiggerOrEqualValue(startOfDay))
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)]))
      .get();
  }

  // Quiz Result Queries
  Future<int> createQuizResult(QuizResultsCompanion result) => into(quizResults).insert(result);

  Future<bool> updateQuizResult(QuizResult result) =>
      update(quizResults).replace(result);

  Future<List<QuizResult>> getQuizResultsByDeck(int deckId) => (select(quizResults)
        ..where((tbl) => tbl.deckId.equals(deckId))
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.completedAt)]))
      .get();

  Future<List<QuizResult>> getRecentQuizResults(int limit) => (select(quizResults)
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.completedAt)])
        ..limit(limit))
      .get();

  Future<List<QuizResult>> getTodayQuizResults() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return (select(quizResults)
        ..where((tbl) => tbl.completedAt.isBiggerOrEqualValue(startOfDay))
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.completedAt)]))
      .get();
  }

  // Analytics aggregation queries
  Future<int> getTotalDecks() async {
    final result = await (select(decks)
        ..where((tbl) => tbl.deletedAt.isNull()))
        .get();
    return result.length;
  }

  Future<int> getTotalFlashcards() async {
    final cards = await (select(flashcards)
        ..where((tbl) => tbl.deletedAt.isNull()))
        .get();
    return cards.length;
  }

  Future<int> getCardsStudiedToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final sessions = await (select(studySessions)
        ..where((tbl) => tbl.startedAt.isBiggerOrEqualValue(startOfDay)))
        .get();
    return sessions.fold<int>(
        0, (sum, session) => sum + session.cardsStudied);
  }

  Future<int> getDueTodayCount() async {
    final cards = await (select(flashcards)
        ..where((tbl) => tbl.nextReviewAt.isSmallerThanValue(DateTime.now()))
        ..where((tbl) => tbl.deletedAt.isNull()))
        .get();
    return cards.length;
  }

  Future<int> getCurrentStreak() async {
    // Calculate consecutive days with study activity
    final sessions = await (select(studySessions)
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)]))
        .get();

    if (sessions.isEmpty) return 0;

    int streak = 0;
    DateTime? checkDate = DateTime.now();

    for (final session in sessions) {
      final sessionDate = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      );

      if (checkDate == null ||
          sessionDate.isAtSameMomentAs(checkDate) ||
          sessionDate.isAtSameMomentAs(checkDate.subtract(const Duration(days: 1)))) {
        streak++;
        checkDate = sessionDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Future<double> getAverageQuizScore() {
    return select(quizResults)
        .get()
        .then((results) {
          if (results.isEmpty) return 0.0;
          final totalScore = results.fold<double>(
              0.0, (sum, result) => sum + result.score);
          return totalScore / results.length;
        });
  }

  Future<List<DailyStudyActivity>> getDailyStudyActivity(int days) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days - 1));
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);

    final sessions = await (select(studySessions)
        ..where((tbl) => tbl.startedAt.isBiggerOrEqualValue(startOfDay))
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.startedAt)]))
        .get();

    final Map<String, DailyStudyActivity> activityMap = {};

    for (final session in sessions) {
      final dateKey = '${session.startedAt.year}-${session.startedAt.month}-${session.startedAt.day}';
      
      if (!activityMap.containsKey(dateKey)) {
        activityMap[dateKey] = DailyStudyActivity(
          date: session.startedAt,
          cardsStudied: 0,
          studyTimeMinutes: 0,
          accuracy: 0.0,
        );
      }

      final activity = activityMap[dateKey]!;
      activityMap[dateKey] = DailyStudyActivity(
        date: activity.date,
        cardsStudied: activity.cardsStudied + session.cardsStudied,
        studyTimeMinutes: activity.studyTimeMinutes + (session.durationSeconds / 60).round(),
        accuracy: session.cardsStudied > 0
            ? ((activity.cardsStudied * activity.accuracy + session.cardsCorrect) / (activity.cardsStudied + session.cardsStudied)) * 100
            : activity.accuracy,
      );
    }

    // Fill in missing days
    final List<DailyStudyActivity> activities = [];
    for (int i = 0; i < days; i++) {
      final date = startOfDay.add(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      activities.add(activityMap[dateKey] ?? DailyStudyActivity(
        date: date,
        cardsStudied: 0,
        studyTimeMinutes: 0,
        accuracy: 0.0,
      ));
    }

    return activities;
  }

  Future<List<MasteryDistribution>> getMasteryDistribution() async {
    final cards = await (select(flashcards)
        ..where((tbl) => tbl.deletedAt.isNull()))
        .get();

    int mastered = 0; // interval > 21 days
    int learning = 0; // interval between 1-21 days
    int newCards = 0; // interval == 0

    for (final card in cards) {
      if (card.interval > 21) {
        mastered++;
      } else if (card.interval > 0) {
        learning++;
      } else {
        newCards++;
      }
    }

    return [
      MasteryDistribution(level: 'Mastered', count: mastered, percentage: cards.isEmpty ? 0.0 : mastered / cards.length * 100),
      MasteryDistribution(level: 'Learning', count: learning, percentage: cards.isEmpty ? 0.0 : learning / cards.length * 100),
      MasteryDistribution(level: 'New', count: newCards, percentage: cards.isEmpty ? 0.0 : newCards / cards.length * 100),
    ];
  }

  Future<List<DeckAccuracy>> getAccuracyByDeck() async {
    final decks = await getAllDecks();
    final List<DeckAccuracy> accuracies = [];

    for (final deck in decks) {
      final cards = await getFlashcardsByDeck(deck.id);
      
      if (cards.isEmpty) {
        accuracies.add(DeckAccuracy(
          deckId: deck.id,
          deckName: deck.name,
          accuracy: 0.0,
          totalCards: 0,
        ));
        continue;
      }

      int totalReviews = 0;
      int totalCorrect = 0;

      for (final card in cards) {
        totalReviews += card.reviewCount;
        totalCorrect += card.correctCount;
      }

      accuracies.add(DeckAccuracy(
        deckId: deck.id,
        deckName: deck.name,
        accuracy: totalReviews > 0 ? (totalCorrect / totalReviews * 100) : 0.0,
        totalCards: cards.length,
      ));
    }

    accuracies.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return accuracies;
  }
}

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'quizsnap.db'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    return NativeDatabase.createInBackground(file);
  });
}



// Analytics data classes
class DailyStudyActivity {
  final DateTime date;
  final int cardsStudied;
  final int studyTimeMinutes;
  final double accuracy;

  DailyStudyActivity({
    required this.date,
    required this.cardsStudied,
    required this.studyTimeMinutes,
    required this.accuracy,
  });
}

class MasteryDistribution {
  final String level;
  final int count;
  final double percentage;

  MasteryDistribution({
    required this.level,
    required this.count,
    required this.percentage,
  });
}

class DeckAccuracy {
  final int deckId;
  final String deckName;
  final double accuracy;
  final int totalCards;

  DeckAccuracy({
    required this.deckId,
    required this.deckName,
    required this.accuracy,
    required this.totalCards,
  });
}
