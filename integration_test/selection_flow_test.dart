import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:quiz_snap/core/database/database.dart';
import 'package:quiz_snap/core/providers/database_provider.dart';
import 'package:quiz_snap/core/providers/deck_bookmark_provider.dart';
import 'package:quiz_snap/core/providers/flashcard_selection_provider.dart';
import 'package:quiz_snap/core/providers/notification_service.dart';
import 'package:quiz_snap/core/providers/trash_provider.dart';
import 'package:quiz_snap/core/services/trash_service.dart';
import 'package:quiz_snap/features/decks/deck_details_screen.dart';
import 'package:quiz_snap/features/trash/trash_screen.dart';
import 'package:quiz_snap/shared/widgets/selectable_flashcard_tile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late DatabaseProvider dbProvider;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    database = AppDatabase(NativeDatabase.memory());
    dbProvider = DatabaseProvider.test(database);
  });

  tearDown(() async {
    await database.close();
  });

  Widget buildDeckApp(int deckId) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dbProvider),
        ChangeNotifierProvider(create: (_) => DeckBookmarkProvider(prefs)),
        ChangeNotifierProvider(create: (_) => FlashcardSelectionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        home: DeckDetailsScreen(deckId: deckId),
      ),
    );
  }

  Widget buildTrashApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dbProvider),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(
          create: (_) => TrashProvider(
            TrashService(
              deckRepository: dbProvider.deckRepository,
              flashcardRepository: dbProvider.flashcardRepository,
            ),
          ),
        ),
      ],
      child: const MaterialApp(
        home: TrashScreen(),
      ),
    );
  }

  testWidgets('select a card, delete it, and restore it from Trash', (tester) async {
    final deckId = await database.createDeck(
      const DecksCompanion(name: Value('Restore Flow'), color: Value('#FF9800')),
    );
    await database.createFlashcard(
      FlashcardsCompanion(
        question: const Value('Delete and restore me'),
        answer: const Value('Answer'),
        deckId: Value(deckId),
        order: const Value(1),
        isFavorite: const Value(true),
      ),
    );

    await tester.pumpWidget(buildDeckApp(deckId));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(SelectableFlashcardTile).first);
    await tester.longPress(find.byType(SelectableFlashcardTile).first);
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();

    expect((await database.getFlashcardsByDeck(deckId)).length, 0);

    await tester.pumpWidget(buildTrashApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();

    expect(find.text('Delete and restore me'), findsOneWidget);

    final cardRestore = find.byIcon(Icons.restore).last;
    await tester.tap(cardRestore);
    await tester.pumpAndSettle();

    expect(find.text('Delete and restore me'), findsNothing);

    final restoredCards = await database.getFlashcardsByDeck(deckId);
    expect(restoredCards.length, 1);
    expect(restoredCards.first.question, 'Delete and restore me');
    expect(restoredCards.first.isFavorite, true);

    // Allow the success banner's dismiss timer to finish.
    await tester.pump(const Duration(seconds: 4));
  });
}
