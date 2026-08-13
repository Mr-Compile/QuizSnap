import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'dart:io';

part 'database.g.dart';
part 'database_json_extensions.dart';

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

class AiUsage extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()(); // Store date as YYYY-MM-DD string
  IntColumn get usedCount => integer().withDefault(const Constant(0))();
  IntColumn get dailyLimit => integer().withDefault(const Constant(15))();
  DateTimeColumn get lastResetAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class ExtractedDocuments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fileName => text().withLength(min: 1, max: 255)();
  TextColumn get filePath => text().withLength(min: 1, max: 500)();
  TextColumn get extractedText => text()();
  TextColumn get selectedScope => text().withDefault(const Constant('all'))(); // 'all', 'pages', 'headings', 'highlighted'
  TextColumn get scopeDetails => text().nullable()(); // JSON string with page numbers, heading names, etc.
  IntColumn get totalPages => integer().withDefault(const Constant(0))();
  IntColumn get characterCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
}

@DriftDatabase(tables: [Folders, Decks, Flashcards, Tags, FlashcardTags, StudySessions, QuizResults, AiUsage, ExtractedDocuments])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

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
        if (from == 3 && to == 4) {
          // Add AI usage and document extraction tables
          await m.createTable(aiUsage);
          await m.createTable(extractedDocuments);
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

  Future<bool> deleteFolder(int id) async {
    // Unassign active decks so they don't reference a deleted folder.
    await (update(decks)
          ..where((tbl) => tbl.folderId.equals(id))
          ..where((tbl) => tbl.deletedAt.isNull()))
        .write(DecksCompanion(
          folderId: const Value(null),
          updatedAt: Value(DateTime.now()),
        ));

    final folder = await getFolderById(id);
    final updatedFolder = folder.copyWith(deletedAt: Value(DateTime.now()));
    return await update(folders).replace(updatedFolder);
  }

  Future<bool> restoreFolder(int id) async {
    final folder = await getFolderById(id);
    final updatedFolder = folder.copyWith(deletedAt: const Value(null));
    return await update(folders).replace(updatedFolder);
  }

  Future<List<Folder>> getDeletedFolders() => (select(folders)
      ..where((tbl) => tbl.deletedAt.isNotNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.deletedAt)]))
    .get();

  Future<void> permanentlyDeleteFolder(int id) async {
    // Remove the reference from any linked decks before deleting the folder.
    await (update(decks)
          ..where((tbl) => tbl.folderId.equals(id)))
        .write(DecksCompanion(
          folderId: const Value(null),
          updatedAt: Value(DateTime.now()),
        ));
    await (delete(folders)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Deck Queries
  Future<List<Deck>> getAllDecks() => (select(decks)
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
      .get();

  Future<List<Deck>> getActiveDecks() => getAllDecks();

  Future<List<Deck>> getDecksByFolder(int folderId) => (select(decks)
        ..where((tbl) => tbl.folderId.equals(folderId))
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
      .get();

  Future<int> getDeckCountForFolder(int folderId) async {
    final result = await (select(decks)
          ..where((tbl) => tbl.folderId.equals(folderId))
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();
    return result.length;
  }

  Future<List<Deck>> getDecksWithoutFolder() => (select(decks)
        ..where((tbl) => tbl.folderId.isNull())
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
      .get();

  Future<int> getDeckCountWithoutFolder() async {
    final result = await (select(decks)
          ..where((tbl) => tbl.folderId.isNull())
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();
    return result.length;
  }

  Future<bool> moveDeckToFolder(int deckId, int? folderId) async {
    final deck = await getDeckById(deckId);
    return update(decks).replace(
      deck.copyWith(
        folderId: Value<int?>(folderId),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<bool> removeDeckFromFolder(int deckId) => moveDeckToFolder(deckId, null);

  Future<Deck> getDeckById(int id) => (select(decks)
        ..where((tbl) => tbl.id.equals(id))
        ..where((tbl) => tbl.deletedAt.isNull()))
      .getSingle();

  Future<int> createDeck(DecksCompanion deck) => into(decks).insert(deck);

  Future<bool> updateDeck(Deck deck) => update(decks).replace(deck);

  Future<bool> deleteDeck(int id) async {
    final now = DateTime.now();
    final deck = await getDeckById(id);
    final updatedDeck = deck.copyWith(deletedAt: Value(now));
    // Soft-delete related flashcards so they no longer appear in study lists.
    await (update(flashcards)
          ..where((tbl) => tbl.deckId.equals(id)))
        .write(FlashcardsCompanion(deletedAt: Value(now)));
    return await update(decks).replace(updatedDeck);
  }

  Future<bool> restoreDeck(int id) async {
    final deck = await (select(decks)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
    final updatedDeck = deck.copyWith(deletedAt: const Value(null));
    // Restore related flashcards along with the deck.
    await (update(flashcards)
          ..where((tbl) => tbl.deckId.equals(id)))
        .write(const FlashcardsCompanion(deletedAt: Value(null)));
    final result = await update(decks).replace(updatedDeck);
    await updateDeckCardCount(id);
    return result;
  }

  Future<List<Deck>> getDeletedDecks() => (select(decks)
      ..where((tbl) => tbl.deletedAt.isNotNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.deletedAt)]))
    .get();

  Future<void> permanentlyDeleteDeck(int id) async {
    // Remove related flashcards and their tag links first to avoid FK violations.
    final flashcardIds = await (select(flashcards)
          ..where((tbl) => tbl.deckId.equals(id)))
        .map((row) => row.id)
        .get();
    for (final flashcardId in flashcardIds) {
      await (delete(flashcardTags)
            ..where((tbl) => tbl.flashcardId.equals(flashcardId)))
          .go();
    }
    await (delete(flashcards)..where((tbl) => tbl.deckId.equals(id))).go();
    await (delete(decks)..where((tbl) => tbl.id.equals(id))).go();
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

  Future<List<Flashcard>> getActiveFlashcards() => getAllFlashcards();

  Future<List<Flashcard>> getFlashcardsByDeck(int deckId) => (select(flashcards)
        ..where((tbl) => tbl.deckId.equals(deckId))
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.order)]))
      .get();

  Future<List<Flashcard>> getActiveFlashcardsByDeck(int deckId) => getFlashcardsByDeck(deckId);

  Future<Flashcard> getFlashcardById(int id) => (select(flashcards)
        ..where((tbl) => tbl.id.equals(id))
        ..where((tbl) => tbl.deletedAt.isNull()))
      .getSingle();

  Future<int> createFlashcard(FlashcardsCompanion flashcard) =>
      into(flashcards).insert(flashcard);

  Future<bool> updateFlashcard(Flashcard flashcard) =>
      update(flashcards).replace(flashcard);

  Future<bool> deleteFlashcard(int id) async {
    final flashcard = await getFlashcardById(id);
    final updatedFlashcard = flashcard.copyWith(deletedAt: Value(DateTime.now()));
    final result = await update(flashcards).replace(updatedFlashcard);
    await updateDeckCardCount(flashcard.deckId);
    return result;
  }

  Future<bool> restoreFlashcard(int id) async {
    final flashcard = await (select(flashcards)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
    final updatedFlashcard = flashcard.copyWith(deletedAt: const Value(null));
    final result = await update(flashcards).replace(updatedFlashcard);
    await updateDeckCardCount(flashcard.deckId);
    return result;
  }

  Future<List<Flashcard>> getDeletedFlashcards() => (select(flashcards)
      ..where((tbl) => tbl.deletedAt.isNotNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.deletedAt)]))
    .get();

  Future<void> permanentlyDeleteFlashcard(int id) async {
    final flashcard = await (select(flashcards)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
    await (delete(flashcardTags)
          ..where((tbl) => tbl.flashcardId.equals(id)))
        .go();
    await (delete(flashcards)..where((tbl) => tbl.id.equals(id))).go();
    await updateDeckCardCount(flashcard.deckId);
  }

  Future<bool> moveFlashcard(int id, int newDeckId) async {
    final flashcard = await (select(flashcards)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
    final existingCards = await (select(flashcards)
          ..where((tbl) => tbl.deckId.equals(newDeckId))
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();
    final maxOrder = existingCards.isEmpty
        ? 0
        : existingCards.map((f) => f.order).reduce((a, b) => a > b ? a : b);
    final oldDeckId = flashcard.deckId;

    final updatedFlashcard = flashcard.copyWith(
      deckId: newDeckId,
      order: maxOrder + 1,
      deletedAt: const Value(null),
    );
    final result = await update(flashcards).replace(updatedFlashcard);
    await updateDeckCardCount(oldDeckId);
    await updateDeckCardCount(newDeckId);
    return result;
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

  Future<int> updateFlashcardReview(int id, bool correct) async {
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

    return await (update(flashcards)..where((tbl) => tbl.id.equals(id)))
        .write(FlashcardsCompanion(
          reviewCount: Value(newReviewCount),
          correctCount: Value(newCorrectCount),
          lastReviewedAt: Value(now),
          nextReviewAt: Value(nextReview),
        ));
  }

  // SM-2 Algorithm implementation
  Future<int> updateFlashcardReviewSM2(int id, int quality) async {
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
    
    return await (update(flashcards)..where((tbl) => tbl.id.equals(id)))
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

  Future<void> deleteTag(int id) async {
    await (delete(tags)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Flashcard Tag Queries
  Future<List<Tag>> getTagsForFlashcard(int flashcardId) async {
    final query = select(tags).join([
      innerJoin(
        flashcardTags,
        flashcardTags.tagId.equalsExp(tags.id),
      ),
    ])
      ..where(flashcardTags.flashcardId.equals(flashcardId))
      ..orderBy([OrderingTerm.asc(tags.name)]);

    return await query.map((row) => row.readTable(tags)).get();
  }

  Future<int> addTagToFlashcard(int flashcardId, int tagId) =>
      into(flashcardTags).insert(FlashcardTagsCompanion(
            flashcardId: Value(flashcardId),
            tagId: Value(tagId),
          ), mode: InsertMode.insertOrIgnore);

  Future<void> removeTagFromFlashcard(int flashcardId, int tagId) async {
    await (delete(flashcardTags)
        ..where((tbl) => tbl.flashcardId.equals(flashcardId))
        ..where((tbl) => tbl.tagId.equals(tagId)))
      .go();
  }

  Future<void> setFlashcardTags(int flashcardId, List<int> tagIds) async {
    await (delete(flashcardTags)
        ..where((tbl) => tbl.flashcardId.equals(flashcardId)))
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

  // AI Usage Queries
  Future<List<AiUsageData>> getAllAiUsage() => (select(aiUsage)).get();

  Future<AiUsageData?> getAiUsageForDate(String date) => (select(aiUsage)
        ..where((tbl) => tbl.date.equals(date)))
      .getSingleOrNull();

  Future<int> createAiUsage(AiUsageCompanion usage) => into(aiUsage).insert(usage);

  Future<bool> updateAiUsage(AiUsageData usage) => update(aiUsage).replace(usage);

  Future<int> deleteAllAiUsage() => (delete(aiUsage)).go();

  // Extracted Documents Queries
  Future<List<ExtractedDocument>> getAllExtractedDocuments() => (select(extractedDocuments)).get();

  Future<ExtractedDocument?> getExtractedDocumentById(int id) => (select(extractedDocuments)
        ..where((tbl) => tbl.id.equals(id)))
      .getSingleOrNull();

  Future<int> createExtractedDocument(ExtractedDocumentsCompanion doc) => into(extractedDocuments).insert(doc);

  Future<bool> updateExtractedDocument(ExtractedDocument doc) => update(extractedDocuments).replace(doc);

  Future<bool> deleteExtractedDocument(int id) async {
    final result = await (delete(extractedDocuments)
        ..where((tbl) => tbl.id.equals(id)))
      .go();
    return result > 0;
  }

  Future<int> deleteAllExtractedDocuments() => (delete(extractedDocuments)).go();

  Future<List<ExtractedDocument>> searchExtractedDocuments(String query) {
    final searchTerm = '%$query%';
    return (select(extractedDocuments)
        ..where((tbl) => tbl.fileName.like(searchTerm)))
      .get();
  }

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

  Future<List<Flashcard>> searchActiveFlashcards(String query) => searchFlashcards(query);

  Future<List<Deck>> searchDecks(String query) {
    final searchTerm = '%$query%';
    return (select(decks)
        ..where((tbl) => tbl.name.like(searchTerm) |
            (tbl.description.like(searchTerm)))
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
      .get();
  }

  Future<List<Deck>> searchActiveDecks(String query) => searchDecks(query);

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
    // Calculate consecutive days with study activity, grouping by date
    final sessions = await (select(studySessions)
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)]))
      .get();

    if (sessions.isEmpty) return 0;

    final studyDates = <DateTime>{}; // Use a set to store unique dates
    for (final session in sessions) {
      studyDates.add(DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      ));
    }

    final sortedDates = studyDates.toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (sortedDates.first != today && sortedDates.first != yesterday) {
      return 0;
    }

    int streak = 1;
    DateTime lastDate = sortedDates.first;
    for (int i = 1; i < sortedDates.length; i++) {
      final expected = lastDate.subtract(const Duration(days: 1));
      if (sortedDates[i] == expected) {
        streak++;
        lastDate = sortedDates[i];
      } else if (sortedDates[i].isBefore(expected)) {
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
              0.0, (sum, result) => sum + (result.score.toDouble()));
          return totalScore / results.length.toDouble();
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
      final newCardsStudied = activity.cardsStudied + session.cardsStudied;
      final newStudyTimeMinutes = activity.studyTimeMinutes + (session.durationSeconds / 60).round();
      
      // Calculate weighted average accuracy
      double newAccuracy;
      if (newCardsStudied > 0) {
        final totalCorrect = (activity.cardsStudied * activity.accuracy / 100).round() + session.cardsCorrect;
        newAccuracy = (totalCorrect / newCardsStudied) * 100;
      } else {
        newAccuracy = activity.accuracy;
      }
      
      activityMap[dateKey] = DailyStudyActivity(
        date: activity.date,
        cardsStudied: newCardsStudied,
        studyTimeMinutes: newStudyTimeMinutes,
        accuracy: newAccuracy,
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

    final totalCards = cards.length;
    final masteredPercentage = totalCards > 0 ? (mastered.toDouble() / totalCards.toDouble() * 100.0) : 0.0;
    final learningPercentage = totalCards > 0 ? (learning.toDouble() / totalCards.toDouble() * 100.0) : 0.0;
    final newCardsPercentage = totalCards > 0 ? (newCards.toDouble() / totalCards.toDouble() * 100.0) : 0.0;

    return [
      MasteryDistribution(level: 'Mastered', count: mastered, percentage: masteredPercentage),
      MasteryDistribution(level: 'Learning', count: learning, percentage: learningPercentage),
      MasteryDistribution(level: 'New', count: newCards, percentage: newCardsPercentage),
    ];
  }

  Future<int> getTotalStudyMinutes() async {
    final sessions = await (select(studySessions)).get();
    final totalSeconds = sessions.fold<int>(
        0, (sum, session) => sum + session.durationSeconds);
    return totalSeconds ~/ 60;
  }

  Future<int> getTotalCardsReviewed() async {
    final sessions = await (select(studySessions)).get();
    return sessions.fold<int>(
        0, (sum, session) => sum + session.cardsStudied);
  }

  Future<int> getQuizAttemptCount() async {
    final results = await (select(quizResults)).get();
    return results.length;
  }

  Future<List<DeckAccuracy>> getAccuracyByDeck() async {
    try {
      final decks = await getAllDecks();
      final List<DeckAccuracy> accuracies = [];

      for (final deck in decks) {
        // Skip deleted decks
        if (deck.deletedAt != null) continue;

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
          // Skip deleted cards
          if (card.deletedAt != null) continue;
          
          totalReviews += card.reviewCount;
          totalCorrect += card.correctCount;
        }

        // Avoid division by zero - ensure double type
        final accuracy = totalReviews > 0 
            ? (totalCorrect.toDouble() / totalReviews.toDouble() * 100.0) 
            : 0.0;

        accuracies.add(DeckAccuracy(
          deckId: deck.id,
          deckName: deck.name,
          accuracy: accuracy, // Already a double
          totalCards: cards.length, // Already an int
        ));
      }

      accuracies.sort((a, b) => a.accuracy.compareTo(b.accuracy));
      return accuracies;
    } catch (e) {
      // Return empty list on error to prevent crashes
      return [];
    }
  }

  Future<int> getRemainingQuota() async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final usage = await getAiUsageForDate(dateStr);
    if (usage == null) return 15; // Default daily limit

    return usage.dailyLimit - usage.usedCount;
  }

  Future<bool> incrementAiUsage() async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final usage = await getAiUsageForDate(dateStr);

    if (usage == null) {
      // Create new entry for today
      await into(aiUsage).insert(AiUsageCompanion(
        date: Value(dateStr),
        usedCount: const Value(1),
        dailyLimit: const Value(15),
        lastResetAt: Value(today),
      ));
      return true;
    } else {
      // Check if we need to reset (new day)
      if (usage.lastResetAt.day != today.day ||
          usage.lastResetAt.month != today.month ||
          usage.lastResetAt.year != today.year) {
        // Reset for new day
        await (update(aiUsage)..where((tbl) => tbl.id.equals(usage.id))).write(
          AiUsageCompanion(
            usedCount: const Value(1),
            lastResetAt: Value(today),
            updatedAt: Value(DateTime.now()),
          ),
        );
        return true;
      }

      // Check if limit reached
      if (usage.usedCount >= usage.dailyLimit) {
        return false;
      }

      // Increment usage
      await (update(aiUsage)..where((tbl) => tbl.id.equals(usage.id))).write(
        AiUsageCompanion(
          usedCount: Value(usage.usedCount + 1),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return true;
    }
  }

  Future<List<AiUsageData>> getAiUsageHistory({int limit = 30}) => (select(aiUsage)
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)])
        ..limit(limit))
      .get();

  Future<void> updateDocumentLastUsed(int id) async {
    final doc = await getExtractedDocumentById(id);
    if (doc != null) {
      await update(extractedDocuments).replace(doc.copyWith(lastUsedAt: Value(DateTime.now())));
    }
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
