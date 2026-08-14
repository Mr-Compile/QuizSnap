import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quiz_snap/main.dart';
import 'package:quiz_snap/core/database/database.dart';
import 'package:quiz_snap/core/providers/database_provider.dart';
import 'package:quiz_snap/core/providers/security_provider.dart';
import 'package:quiz_snap/core/services/session_inactivity_service.dart';
import 'package:quiz_snap/core/providers/focus_mode_provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:quiz_snap/core/providers/deck_bookmark_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Selection Flow Integration Tests', () {
    late DatabaseProvider dbProvider;
    late DeckBookmarkProvider bookmarkProvider;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      dbProvider = DatabaseProvider();
      await dbProvider.initializeDatabase();
      bookmarkProvider = DeckBookmarkProvider(prefs);
    });

    tearDown(() async {
      dbProvider.dispose();
    });

    testWidgets('Delete → Trash → Restore flow for flashcard', (WidgetTester tester) async {
      // Build the app
      final securityProvider = SecurityProvider();
      await securityProvider.initialize();
      final focusModeProvider = FocusModeProvider();
      final sessionInactivityService = SessionInactivityService(securityProvider);
      sessionInactivityService.attachFocusModeProvider(focusModeProvider);
      await tester.pumpWidget(QuizSnapApp(
        prefs: prefs,
        dbProvider: dbProvider,
        securityProvider: securityProvider,
        sessionInactivityService: sessionInactivityService,
        focusModeProvider: focusModeProvider,
      ));
      await tester.pumpAndSettle();

      // Create a test deck
      final deck = DecksCompanion(
        name: const Value('Test Deck'),
        description: const Value('Test Description'),
        color: const Value('#4CAF50'),
      );
      final deckId = await dbProvider.database.createDeck(deck);

      // Create test flashcards
      final flashcard1 = FlashcardsCompanion(
        question: const Value('Question 1'),
        answer: const Value('Answer 1'),
        deckId: Value(deckId),
        isFavorite: const Value(true),
      );
      final flashcard2 = FlashcardsCompanion(
        question: const Value('Question 2'),
        answer: const Value('Answer 2'),
        deckId: Value(deckId),
        isFavorite: const Value(false),
      );

      final card1Id = await dbProvider.database.createFlashcard(flashcard1);
      await dbProvider.database.createFlashcard(flashcard2);

      // Update deck card count
      await dbProvider.database.updateDeckCardCount(deckId);

      // Verify initial state
      final initialDeck = await dbProvider.database.getDeckById(deckId);
      expect(initialDeck.cardCount, equals(2));

      final initialCards = await dbProvider.database.getFlashcardsByDeck(deckId);
      expect(initialCards.length, equals(2));

      // Bookmark the deck
      bookmarkProvider.toggleBookmark(deckId);
      expect(bookmarkProvider.isBookmarked(deckId), isTrue);

      // Delete first flashcard
      await dbProvider.database.deleteFlashcard(card1Id);
      await dbProvider.database.updateDeckCardCount(deckId);

      // Verify flashcard is deleted from deck
      final afterDeleteCards = await dbProvider.database.getFlashcardsByDeck(deckId);
      expect(afterDeleteCards.length, equals(1));
      expect(afterDeleteCards.first.id, isNot(equals(card1Id)));

      // Verify deck count updated
      final afterDeleteDeck = await dbProvider.database.getDeckById(deckId);
      expect(afterDeleteDeck.cardCount, equals(1));

      // Verify flashcard appears in trash
      final deletedFlashcards = await dbProvider.database.getDeletedFlashcards();
      expect(deletedFlashcards.length, greaterThan(0));
      final deletedCard = deletedFlashcards.firstWhere((card) => card.id == card1Id);
      expect(deletedCard.deletedAt, isNotNull);
      expect(deletedCard.isFavorite, isTrue); // Bookmark state preserved

      // Restore flashcard
      await dbProvider.database.restoreFlashcard(card1Id);
      await dbProvider.database.updateDeckCardCount(deckId);

      // Verify flashcard restored to deck
      final afterRestoreCards = await dbProvider.database.getFlashcardsByDeck(deckId);
      expect(afterRestoreCards.length, equals(2));
      expect(afterRestoreCards.any((card) => card.id == card1Id), isTrue);

      // Verify deck count updated
      final afterRestoreDeck = await dbProvider.database.getDeckById(deckId);
      expect(afterRestoreDeck.cardCount, equals(2));

      // Verify bookmark state preserved
      final restoredCard = afterRestoreCards.firstWhere((card) => card.id == card1Id);
      expect(restoredCard.isFavorite, isTrue);

      // Verify flashcard removed from trash
      final finalDeletedFlashcards = await dbProvider.database.getDeletedFlashcards();
      expect(finalDeletedFlashcards.any((card) => card.id == card1Id), isFalse);

      // Verify deck bookmark still intact
      expect(bookmarkProvider.isBookmarked(deckId), isTrue);
    });

    testWidgets('Delete → Trash → Restore flow for deck', (WidgetTester tester) async {
      final securityProvider = SecurityProvider();
      await securityProvider.initialize();
      final focusModeProvider = FocusModeProvider();
      final sessionInactivityService = SessionInactivityService(securityProvider);
      sessionInactivityService.attachFocusModeProvider(focusModeProvider);
      await tester.pumpWidget(QuizSnapApp(
        prefs: prefs,
        dbProvider: dbProvider,
        securityProvider: securityProvider,
        sessionInactivityService: sessionInactivityService,
        focusModeProvider: focusModeProvider,
      ));
      await tester.pumpAndSettle();

      // Create a test folder
      final folder = FoldersCompanion(
        name: const Value('Test Folder'),
        color: const Value('#2196F3'),
      );
      final folderId = await dbProvider.database.createFolder(folder);

      // Create a test deck in folder
      final deck = DecksCompanion(
        name: const Value('Test Deck'),
        description: const Value('Test Description'),
        folderId: Value(folderId),
        color: const Value('#4CAF50'),
      );
      final deckId = await dbProvider.database.createDeck(deck);

      // Create flashcards in deck
      final flashcard = FlashcardsCompanion(
        question: const Value('Question 1'),
        answer: const Value('Answer 1'),
        deckId: Value(deckId),
      );
      await dbProvider.database.createFlashcard(flashcard);
      await dbProvider.database.updateDeckCardCount(deckId);

      // Bookmark the deck
      bookmarkProvider.toggleBookmark(deckId);
      expect(bookmarkProvider.isBookmarked(deckId), isTrue);

      // Delete deck
      await dbProvider.database.deleteDeck(deckId);

      // Verify deck is deleted
      final allDecks = await dbProvider.database.getAllDecks();
      expect(allDecks.any((d) => d.id == deckId), isFalse);

      // Verify deck appears in trash
      final deletedDecks = await dbProvider.database.getDeletedDecks();
      expect(deletedDecks.length, greaterThan(0));
      final deletedDeck = deletedDecks.firstWhere((d) => d.id == deckId);
      expect(deletedDeck.deletedAt, isNotNull);

      // Restore deck
      await dbProvider.database.restoreDeck(deckId);

      // Verify deck restored
      final restoredDecks = await dbProvider.database.getAllDecks();
      expect(restoredDecks.any((d) => d.id == deckId), isTrue);

      final restoredDeck = restoredDecks.firstWhere((d) => d.id == deckId);
      expect(restoredDeck.deletedAt, isNull);
      expect(restoredDeck.folderId, equals(folderId)); // Folder association preserved

      // Verify deck removed from trash
      final finalDeletedDecks = await dbProvider.database.getDeletedDecks();
      expect(finalDeletedDecks.any((d) => d.id == deckId), isFalse);

      // Verify deck bookmark still intact
      expect(bookmarkProvider.isBookmarked(deckId), isTrue);
    });

    testWidgets('Delete → Trash → Restore flow for folder', (WidgetTester tester) async {
      final securityProvider = SecurityProvider();
      await securityProvider.initialize();
      final focusModeProvider = FocusModeProvider();
      final sessionInactivityService = SessionInactivityService(securityProvider);
      sessionInactivityService.attachFocusModeProvider(focusModeProvider);
      await tester.pumpWidget(QuizSnapApp(
        prefs: prefs,
        dbProvider: dbProvider,
        securityProvider: securityProvider,
        sessionInactivityService: sessionInactivityService,
        focusModeProvider: focusModeProvider,
      ));
      await tester.pumpAndSettle();

      // Create a test folder
      final folder = FoldersCompanion(
        name: const Value('Test Folder'),
        description: const Value('Test Description'),
        color: const Value('#2196F3'),
      );
      final folderId = await dbProvider.database.createFolder(folder);

      // Create decks in folder
      final deck1 = DecksCompanion(
        name: const Value('Deck 1'),
        folderId: Value(folderId),
        color: const Value('#4CAF50'),
      );
      final deck2 = DecksCompanion(
        name: const Value('Deck 2'),
        folderId: Value(folderId),
        color: const Value('#FF9800'),
      );
      await dbProvider.database.createDeck(deck1);
      await dbProvider.database.createDeck(deck2);

      // Delete folder
      await dbProvider.database.deleteFolder(folderId);

      // Verify folder is deleted
      final allFolders = await dbProvider.database.getAllFolders();
      expect(allFolders.any((f) => f.id == folderId), isFalse);

      // Verify folder appears in trash
      final deletedFolders = await dbProvider.database.getDeletedFolders();
      expect(deletedFolders.length, greaterThan(0));
      final deletedFolder = deletedFolders.firstWhere((f) => f.id == folderId);
      expect(deletedFolder.deletedAt, isNotNull);

      // Restore folder
      await dbProvider.database.restoreFolder(folderId);

      // Verify folder restored
      final restoredFolders = await dbProvider.database.getAllFolders();
      expect(restoredFolders.any((f) => f.id == folderId), isTrue);

      final restoredFolder = restoredFolders.firstWhere((f) => f.id == folderId);
      expect(restoredFolder.deletedAt, isNull);
      expect(restoredFolder.name, equals('Test Folder'));

      // Verify folder removed from trash
      final finalDeletedFolders = await dbProvider.database.getDeletedFolders();
      expect(finalDeletedFolders.any((f) => f.id == folderId), isFalse);
    });

    testWidgets('Permanent delete functionality', (WidgetTester tester) async {
      final securityProvider = SecurityProvider();
      await securityProvider.initialize();
      final focusModeProvider = FocusModeProvider();
      final sessionInactivityService = SessionInactivityService(securityProvider);
      sessionInactivityService.attachFocusModeProvider(focusModeProvider);
      await tester.pumpWidget(QuizSnapApp(
        prefs: prefs,
        dbProvider: dbProvider,
        securityProvider: securityProvider,
        sessionInactivityService: sessionInactivityService,
        focusModeProvider: focusModeProvider,
      ));
      await tester.pumpAndSettle();

      // Create and delete a flashcard
      final deck = DecksCompanion(
        name: const Value('Test Deck'),
        color: const Value('#4CAF50'),
      );
      final deckId = await dbProvider.database.createDeck(deck);

      final flashcard = FlashcardsCompanion(
        question: const Value('Question 1'),
        answer: const Value('Answer 1'),
        deckId: Value(deckId),
      );
      final cardId = await dbProvider.database.createFlashcard(flashcard);

      await dbProvider.database.deleteFlashcard(cardId);

      // Verify in trash
      final deletedFlashcards = await dbProvider.database.getDeletedFlashcards();
      expect(deletedFlashcards.any((card) => card.id == cardId), isTrue);

      // Permanently delete
      await dbProvider.database.permanentlyDeleteFlashcard(cardId);

      // Verify removed from trash
      final finalDeletedFlashcards = await dbProvider.database.getDeletedFlashcards();
      expect(finalDeletedFlashcards.any((card) => card.id == cardId), isFalse);

      // Verify cannot restore
      final allFlashcards = await dbProvider.database.getAllFlashcards();
      expect(allFlashcards.any((card) => card.id == cardId), isFalse);
    });

    testWidgets('Provider state consistency during delete/restore', (WidgetTester tester) async {
      final securityProvider = SecurityProvider();
      await securityProvider.initialize();
      final focusModeProvider = FocusModeProvider();
      final sessionInactivityService = SessionInactivityService(securityProvider);
      sessionInactivityService.attachFocusModeProvider(focusModeProvider);
      await tester.pumpWidget(QuizSnapApp(
        prefs: prefs,
        dbProvider: dbProvider,
        securityProvider: securityProvider,
        sessionInactivityService: sessionInactivityService,
        focusModeProvider: focusModeProvider,
      ));
      await tester.pumpAndSettle();

      // Create test data
      final deck = DecksCompanion(
        name: const Value('Test Deck'),
        color: const Value('#4CAF50'),
      );
      final deckId = await dbProvider.database.createDeck(deck);

      final flashcard = FlashcardsCompanion(
        question: const Value('Question 1'),
        answer: const Value('Answer 1'),
        deckId: Value(deckId),
      );
      final cardId = await dbProvider.database.createFlashcard(flashcard);
      await dbProvider.database.updateDeckCardCount(deckId);

      // Test provider refresh
      dbProvider.refreshDecks();
      await tester.pumpAndSettle();

      // Delete flashcard
      await dbProvider.database.deleteFlashcard(cardId);
      await dbProvider.database.updateDeckCardCount(deckId);
      dbProvider.refreshDecks();
      await tester.pumpAndSettle();

      // Verify provider state updated
      final decksAfterDelete = await dbProvider.deckRepository.getAllDecks();
      final deckAfterDelete = decksAfterDelete.firstWhere((d) => d.id == deckId);
      expect(deckAfterDelete.cardCount, equals(0));

      // Restore flashcard
      await dbProvider.database.restoreFlashcard(cardId);
      await dbProvider.database.updateDeckCardCount(deckId);
      dbProvider.refreshDecks();
      await tester.pumpAndSettle();

      // Verify provider state updated
      final decksAfterRestore = await dbProvider.deckRepository.getAllDecks();
      final deckAfterRestore = decksAfterRestore.firstWhere((d) => d.id == deckId);
      expect(deckAfterRestore.cardCount, equals(1));
    });

    testWidgets('Navigation and UI flow for delete/restore', (WidgetTester tester) async {
      final securityProvider = SecurityProvider();
      await securityProvider.initialize();
      final focusModeProvider = FocusModeProvider();
      final sessionInactivityService = SessionInactivityService(securityProvider);
      sessionInactivityService.attachFocusModeProvider(focusModeProvider);
      await tester.pumpWidget(QuizSnapApp(
        prefs: prefs,
        dbProvider: dbProvider,
        securityProvider: securityProvider,
        sessionInactivityService: sessionInactivityService,
        focusModeProvider: focusModeProvider,
      ));
      await tester.pumpAndSettle();

      // Create test data
      final deck = DecksCompanion(
        name: const Value('Test Deck'),
        color: const Value('#4CAF50'),
      );
      final deckId = await dbProvider.database.createDeck(deck);

      final flashcard = FlashcardsCompanion(
        question: const Value('Question 1'),
        answer: const Value('Answer 1'),
        deckId: Value(deckId),
      );
      await dbProvider.database.createFlashcard(flashcard);
      await dbProvider.database.updateDeckCardCount(deckId);
      dbProvider.refreshDecks();
      await tester.pumpAndSettle();

      // Navigate to deck details
      // Note: This would require actual navigation testing implementation
      // For now, we verify the data state which is critical for the flow

      final deckBeforeDelete = await dbProvider.database.getDeckById(deckId);
      expect(deckBeforeDelete.cardCount, equals(1));

      // Delete and verify
      await dbProvider.database.deleteFlashcard(1); // Assuming ID 1
      await dbProvider.database.updateDeckCardCount(deckId);
      dbProvider.refreshDecks();
      await tester.pumpAndSettle();

      final deckAfterDelete = await dbProvider.database.getDeckById(deckId);
      expect(deckAfterDelete.cardCount, equals(0));
    });
  });

  group('Selection Count and Analytics Tests', () {
    late DatabaseProvider dbProvider;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      dbProvider = DatabaseProvider();
      await dbProvider.initializeDatabase();
    });

    tearDown(() async {
      dbProvider.dispose();
    });

    testWidgets('Selected count tracking', (WidgetTester tester) async {
      final securityProvider = SecurityProvider();
      await securityProvider.initialize();
      final focusModeProvider = FocusModeProvider();
      final sessionInactivityService = SessionInactivityService(securityProvider);
      sessionInactivityService.attachFocusModeProvider(focusModeProvider);
      await tester.pumpWidget(QuizSnapApp(
        prefs: prefs,
        dbProvider: dbProvider,
        securityProvider: securityProvider,
        sessionInactivityService: sessionInactivityService,
        focusModeProvider: focusModeProvider,
      ));
      await tester.pumpAndSettle();

      // Create multiple flashcards
      final deck = DecksCompanion(
        name: const Value('Test Deck'),
        color: const Value('#4CAF50'),
      );
      final deckId = await dbProvider.database.createDeck(deck);

      for (int i = 0; i < 5; i++) {
        final flashcard = FlashcardsCompanion(
          question: Value('Question $i'),
          answer: Value('Answer $i'),
          deckId: Value(deckId),
        );
        await dbProvider.database.createFlashcard(flashcard);
      }
      await dbProvider.database.updateDeckCardCount(deckId);

      final cards = await dbProvider.database.getFlashcardsByDeck(deckId);
      expect(cards.length, equals(5));

      // Delete multiple cards
      await dbProvider.database.deleteFlashcard(cards[0].id);
      await dbProvider.database.deleteFlashcard(cards[1].id);
      await dbProvider.database.deleteFlashcard(cards[2].id);
      await dbProvider.database.updateDeckCardCount(deckId);

      final remainingCards = await dbProvider.database.getFlashcardsByDeck(deckId);
      expect(remainingCards.length, equals(2));

      final deletedCards = await dbProvider.database.getDeletedFlashcards();
      expect(deletedCards.length, greaterThanOrEqualTo(3));
    });

    testWidgets('Analytics refresh after delete/restore', (WidgetTester tester) async {
      final securityProvider = SecurityProvider();
      await securityProvider.initialize();
      final focusModeProvider = FocusModeProvider();
      final sessionInactivityService = SessionInactivityService(securityProvider);
      sessionInactivityService.attachFocusModeProvider(focusModeProvider);
      await tester.pumpWidget(QuizSnapApp(
        prefs: prefs,
        dbProvider: dbProvider,
        securityProvider: securityProvider,
        sessionInactivityService: sessionInactivityService,
        focusModeProvider: focusModeProvider,
      ));
      await tester.pumpAndSettle();

      // Create deck with cards
      final deck = DecksCompanion(
        name: const Value('Test Deck'),
        color: const Value('#4CAF50'),
      );
      final deckId = await dbProvider.database.createDeck(deck);

      final flashcard = FlashcardsCompanion(
        question: const Value('Question 1'),
        answer: const Value('Answer 1'),
        deckId: Value(deckId),
      );
      await dbProvider.database.createFlashcard(flashcard);
      await dbProvider.database.updateDeckCardCount(deckId);

      // Get initial analytics
      final initialDeck = await dbProvider.database.getDeckById(deckId);
      final initialCount = initialDeck.cardCount;

      // Delete and refresh
      await dbProvider.database.deleteFlashcard(1);
      await dbProvider.database.updateDeckCardCount(deckId);
      dbProvider.refreshDecks();
      await tester.pumpAndSettle();

      // Verify analytics updated
      final afterDeleteDeck = await dbProvider.database.getDeckById(deckId);
      expect(afterDeleteDeck.cardCount, lessThan(initialCount));

      // Restore and refresh
      await dbProvider.database.restoreFlashcard(1);
      await dbProvider.database.updateDeckCardCount(deckId);
      dbProvider.refreshDecks();
      await tester.pumpAndSettle();

      // Verify analytics updated
      final afterRestoreDeck = await dbProvider.database.getDeckById(deckId);
      expect(afterRestoreDeck.cardCount, equals(initialCount));
    });
  });
}