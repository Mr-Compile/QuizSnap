import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:quiz_snap/core/database/database.dart';
import 'package:quiz_snap/core/services/trash_service.dart';
import 'package:quiz_snap/core/repositories/deck_repository.dart';
import 'package:quiz_snap/core/repositories/flashcard_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('TrashService', () {
    test('soft delete deck moves flashcards to trash', () async {
      final deckId = await database.createDeck(
        const DecksCompanion(name: Value('Biology')),
      );
      await database.createFlashcard(
        FlashcardsCompanion(
          question: const Value('Q1'),
          answer: const Value('A1'),
          deckId: Value(deckId),
          order: const Value(1),
        ),
      );

      final trashService = TrashService(
        deckRepository: DeckRepository(database),
        flashcardRepository: FlashcardRepository(database),
      );

      await trashService.permanentlyDeleteDeck(deckId);
      final activeDecks = await trashService.getDeletedDecks();
      expect(activeDecks, isEmpty);
    });

    test('restore deleted deck makes it active', () async {
      final deckId = await database.createDeck(
        const DecksCompanion(name: Value('History')),
      );
      await database.deleteDeck(deckId);

      final trashService = TrashService(
        deckRepository: DeckRepository(database),
        flashcardRepository: FlashcardRepository(database),
      );

      await trashService.restoreDeck(deckId);
      final active = await database.getAllDecks();
      expect(active.length, 1);
      expect(active.first.name, 'History');
    });

    test('move flashcard to another deck', () async {
      final sourceId = await database.createDeck(
        const DecksCompanion(name: Value('Source')),
      );
      final targetId = await database.createDeck(
        const DecksCompanion(name: Value('Target')),
      );
      final cardId = await database.createFlashcard(
        FlashcardsCompanion(
          question: const Value('Q'),
          answer: const Value('A'),
          deckId: Value(sourceId),
          order: const Value(1),
        ),
      );

      await database.moveFlashcard(cardId, targetId);

      final targetCards = await database.getFlashcardsByDeck(targetId);
      final sourceCards = await database.getFlashcardsByDeck(sourceId);

      expect(targetCards.length, 1);
      expect(targetCards.first.question, 'Q');
      expect(sourceCards, isEmpty);
    });

    test('empty trash removes all deleted items', () async {
      final deckId = await database.createDeck(
        const DecksCompanion(name: Value('Temp')),
      );
      await database.deleteDeck(deckId);

      final trashService = TrashService(
        deckRepository: DeckRepository(database),
        flashcardRepository: FlashcardRepository(database),
      );

      await trashService.emptyTrash();
      final deletedDecks = await database.getDeletedDecks();
      final deletedCards = await database.getDeletedFlashcards();

      expect(deletedDecks, isEmpty);
      expect(deletedCards, isEmpty);
    });
  });
}
