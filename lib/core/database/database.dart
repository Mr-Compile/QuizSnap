import 'package:drift/drift.dart';

part 'database.g.dart';

@Dataclass(['folderId'])
class Folders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().withDefault(const Constant('#4CAF50'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

@Dataclass(['deckId'])
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

@Dataclass(['flashcardId'])
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

@Dataclass(['tagId'])
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get color => text().withDefault(const Constant('#4CAF50'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@Dataclass(['flashcardTagId'])
class FlashcardTags extends Table {
  IntColumn get flashcardId => integer().references(Flashcards, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
  
  @override
  Set<Column> get primaryKey => {flashcardId, tagId};
}

@DriftDatabase(tables: [Folders, Decks, Flashcards, Tags, FlashcardTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 2;

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
      },
    );
  }

  // Folder Queries
  Future<List<Folder>> getAllFolders() => select(folders)
      .where((tbl) => tbl.deletedAt.isNull())
      .orderBy([(tbl) => OrderingTerm.asc(tbl.name)])
      .get();

  Future<Folder> getFolderById(int id) => (select(folders)
        ..where((tbl) => tbl.id.equals(id))
        ..where((tbl) => tbl.deletedAt.isNull()))
      .getSingle();

  Future<int> createFolder(FoldersCompanion folder) => into(folders).insert(folder);

  Future<bool> updateFolder(Folder folder) => update(folders).replace(folder);

  Future<bool> deleteFolder(int id) => (update(folders)
        ..where((tbl) => tbl.id.equals(id))
        ..write(const FoldersCompanion(deletedAt: Value(DateTime.now()))))
      .go();

  Future<bool> restoreFolder(int id) => (update(folders)
        ..where((tbl) => tbl.id.equals(id))
        ..write(const FoldersCompanion(deletedAt: Value(null))))
      .go();

  Future<List<Folder>> getDeletedFolders() => select(folders)
      .where((tbl) => tbl.deletedAt.isNotNull())
      .orderBy([(tbl) => OrderingTerm.desc(tbl.deletedAt)])
      .get();

  // Deck Queries
  Future<List<Deck>> getAllDecks() => select(decks)
      .where((tbl) => tbl.deletedAt.isNull())
      .orderBy([(tbl) => OrderingTerm.asc(tbl.name)])
      .get();

  Future<List<Deck>> getDecksByFolder(int folderId) => select(decks)
      ..where((tbl) => tbl.folderId.equals(folderId))
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);

  Future<Deck> getDeckById(int id) => (select(decks)
        ..where((tbl) => tbl.id.equals(id))
        ..where((tbl) => tbl.deletedAt.isNull()))
      .getSingle();

  Future<int> createDeck(DecksCompanion deck) => into(decks).insert(deck);

  Future<bool> updateDeck(Deck deck) => update(decks).replace(deck);

  Future<bool> deleteDeck(int id) => (update(decks)
        ..where((tbl) => tbl.id.equals(id))
        ..write(const DecksCompanion(deletedAt: Value(DateTime.now()))))
      .go();

  Future<bool> restoreDeck(int id) => (update(decks)
        ..where((tbl) => tbl.id.equals(id))
        ..write(const DecksCompanion(deletedAt: Value(null))))
      .go();

  Future<List<Deck>> getDeletedDecks() => select(decks)
      .where((tbl) => tbl.deletedAt.isNotNull())
      .orderBy([(tbl) => OrderingTerm.desc(tbl.deletedAt)])
      .get();

  Future<void> updateDeckCardCount(int deckId) async {
    final count = await (select(flashcards)
          ..where((tbl) => tbl.deckId.equals(deckId))
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get()
        .then((cards) => cards.length);
    
    await (update(decks)..where((tbl) => tbl.id.equals(deckId)))
        .write(DecksCompanion(cardCount: Value(count)));
  }

  // Flashcard Queries
  Future<List<Flashcard>> getAllFlashcards() => select(flashcards)
      .where((tbl) => tbl.deletedAt.isNull())
      .orderBy([(tbl) => OrderingTerm.asc(tbl.order)])
      .get();

  Future<List<Flashcard>> getFlashcardsByDeck(int deckId) => select(flashcards)
      ..where((tbl) => tbl.deckId.equals(deckId))
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.order)]);

  Future<Flashcard> getFlashcardById(int id) => (select(flashcards)
        ..where((tbl) => tbl.id.equals(id))
        ..where((tbl) => tbl.deletedAt.isNull()))
      .getSingle();

  Future<int> createFlashcard(FlashcardsCompanion flashcard) =>
      into(flashcards).insert(flashcard);

  Future<bool> updateFlashcard(Flashcard flashcard) =>
      update(flashcards).replace(flashcard);

  Future<bool> deleteFlashcard(int id) => (update(flashcards)
        ..where((tbl) => tbl.id.equals(id))
        ..write(const FlashcardsCompanion(deletedAt: Value(DateTime.now()))))
      .go();

  Future<bool> restoreFlashcard(int id) => (update(flashcards)
        ..where((tbl) => tbl.id.equals(id))
        ..write(const FlashcardsCompanion(deletedAt: Value(null))))
      .go();

  Future<List<Flashcard>> getDeletedFlashcards() => select(flashcards)
      .where((tbl) => tbl.deletedAt.isNotNull())
      .orderBy([(tbl) => OrderingTerm.desc(tbl.deletedAt)])
      .get();

  Future<List<Flashcard>> getFavoriteFlashcards() => select(flashcards)
      ..where((tbl) => tbl.isFavorite.equals(true))
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastReviewedAt)]);

  Future<List<Flashcard>> getFlashcardsDueForReview() => select(flashcards)
      ..where((tbl) => tbl.nextReviewAt.isSmallerThanValue(DateTime.now()))
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.nextReviewAt)]);

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
  Future<List<Tag>> getAllTags() => select(tags)
      .orderBy([(tbl) => OrderingTerm.asc(tbl.name)])
      .get();

  Future<Tag> getTagById(int id) => (select(tags)
        ..where((tbl) => tbl.id.equals(id)))
      .getSingle();

  Future<int> createTag(TagsCompanion tag) => into(tags).insert(tag);

  Future<bool> updateTag(Tag tag) => update(tags).replace(tag);

  Future<bool> deleteTag(int id) => delete(tags).where((tbl) => tbl.id.equals(id)).go();

  // Flashcard Tag Queries
  Future<List<Tag>> getTagsForFlashcard(int flashcardId) {
    final query = select(tags).join([
      innerJoin(
        flashcardTags,
        flashcardTags.tagId.equalsExp(tags.id),
      ),
    ])
      ..where(flashcardTags.flashcardId.equals(flashcardId))
      ..orderBy([(tbl) => OrderingTerm.asc(tags.name)]);

    return query.map((row) => row.readTable(tags)).get();
  }

  Future<void> addTagToFlashcard(int flashcardId, int tagId) =>
      into(flashcardTags).insert(FlashcardTagsCompanion(
            flashcardId: Value(flashcardId),
            tagId: Value(tagId),
          ), mode: InsertMode.insertOrIgnore);

  Future<void> removeTagFromFlashcard(int flashcardId, int tagId) =>
      (delete(flashcardTags)
            ..where((tbl) => tbl.flashcardId.equals(flashcardId))
            ..where((tbl) => tbl.tagId.equals(tagId)))
          .go();

  Future<void> setFlashcardTags(int flashcardId, List<int> tagIds) async {
    await (delete(flashcardTags)
          ..where((tbl) => tbl.flashcardId.equals(flashcardId)))
        .go();

    for (final tagId in tagIds) {
      await addTagToFlashcard(flashcardId, tagId);
    }
  }

  // Search Queries
  Future<List<Flashcard>> searchFlashcards(String query) {
    final searchTerm = '%$query%';
    return select(flashcards)
        ..where((tbl) => tbl.question.like(searchTerm) |
            tbl.answer.like(searchTerm))
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.order)]);
  }

  Future<List<Deck>> searchDecks(String query) {
    final searchTerm = '%$query%';
    return select(decks)
        ..where((tbl) => tbl.name.like(searchTerm) |
            (tbl.description.like(searchTerm)))
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
  }

  Future<List<Folder>> searchFolders(String query) {
    final searchTerm = '%$query%';
    return select(folders)
        ..where((tbl) => tbl.name.like(searchTerm) |
            (tbl.description.like(searchTerm)))
        ..where((tbl) => tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
  }
}

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'quizsnap.db'));
    
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = await getTemporaryDirectory();
    sqlite3.tempDirectory = cachebase.path;

    return NativeDatabase.createInBackground(file);
  });
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'quizsnap.db'));
    
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = await getTemporaryDirectory();
    sqlite3.tempDirectory = cachebase.path;

    return NativeDatabase.createInBackground(file);
  });
}
