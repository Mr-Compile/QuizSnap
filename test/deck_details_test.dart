import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:quiz_snap/core/database/database.dart';
import 'package:quiz_snap/core/providers/database_provider.dart';
import 'package:quiz_snap/core/providers/deck_bookmark_provider.dart';
import 'package:quiz_snap/core/providers/flashcard_selection_provider.dart';
import 'package:quiz_snap/core/providers/notification_service.dart';
import 'package:quiz_snap/shared/widgets/app_bar.dart';
import 'package:quiz_snap/shared/widgets/selectable_flashcard_tile.dart';
import 'package:quiz_snap/features/decks/deck_details_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late DatabaseProvider dbProvider;
  late SharedPreferences prefs;
  int deckId = 0;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    database = AppDatabase(NativeDatabase.memory());
    dbProvider = DatabaseProvider.test(database);
    deckId = await database.createDeck(
      const DecksCompanion(name: Value('Biology'), color: Value('#4CAF50')),
    );
    await database.createFlashcard(
      FlashcardsCompanion(
        question: const Value('What is photosynthesis?'),
        answer: const Value('Converting light to energy'),
        deckId: Value(deckId),
        order: const Value(1),
      ),
    );
    await database.createFlashcard(
      FlashcardsCompanion(
        question: const Value('What is mitosis?'),
        answer: const Value('Cell division'),
        deckId: Value(deckId),
        order: const Value(2),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  Widget buildApp({required int targetDeckId}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dbProvider),
        ChangeNotifierProvider(create: (_) => DeckBookmarkProvider(prefs)),
        ChangeNotifierProvider(create: (_) => FlashcardSelectionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        home: DeckDetailsScreen(deckId: targetDeckId),
      ),
    );
  }

  testWidgets('loads deck details and flashcards', (tester) async {
    await tester.pumpWidget(buildApp(targetDeckId: deckId));
    await tester.pumpAndSettle();

    expect(find.text('Biology'), findsOneWidget);
    expect(find.text('What is photosynthesis?'), findsOneWidget);
    expect(find.text('What is mitosis?'), findsOneWidget);
  });

  testWidgets('long-press enters selection mode', (tester) async {
    await tester.pumpWidget(buildApp(targetDeckId: deckId));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(SelectableFlashcardTile).first);
    await tester.longPress(find.byType(SelectableFlashcardTile).first);
    await tester.pumpAndSettle();

    expect(find.byType(Checkbox), findsWidgets);
    expect(
      find.descendant(of: find.byType(CustomAppBar), matching: find.text('1 selected')),
      findsOneWidget,
    );
  });

  testWidgets('select all and clear selection', (tester) async {
    await tester.pumpWidget(buildApp(targetDeckId: deckId));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(SelectableFlashcardTile).first);
    await tester.longPress(find.byType(SelectableFlashcardTile).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.select_all));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(CustomAppBar), matching: find.text('2 selected')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(CustomAppBar), matching: find.text('Deck Details')),
      findsOneWidget,
    );
    expect(find.byType(Checkbox), findsNothing);
  });
}
