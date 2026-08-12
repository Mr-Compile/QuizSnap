import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:quiz_snap/core/database/database.dart';
import 'package:quiz_snap/core/providers/database_provider.dart';
import 'package:quiz_snap/core/providers/notification_service.dart';
import 'package:quiz_snap/core/providers/trash_provider.dart';
import 'package:quiz_snap/core/services/trash_service.dart';
import 'package:quiz_snap/features/trash/trash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late DatabaseProvider dbProvider;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    dbProvider = DatabaseProvider.test(database);
  });

  tearDown(() async {
    await database.close();
  });

  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dbProvider),
        ChangeNotifierProvider(
          create: (_) => TrashProvider(
            TrashService(
              deckRepository: dbProvider.deckRepository,
              flashcardRepository: dbProvider.flashcardRepository,
            ),
          ),
        ),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: const MaterialApp(
        home: TrashScreen(),
      ),
    );
  }

  testWidgets('shows empty trash state', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Decks'));
    await tester.pumpAndSettle();

    expect(find.text('No deleted decks'), findsOneWidget);
  });

  testWidgets('shows deleted deck and restore works', (tester) async {
    final deckId = await database.createDeck(
      const DecksCompanion(name: Value('History'), color: Value('#2196F3')),
    );
    await database.deleteDeck(deckId);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Decks'));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(find.byIcon(Icons.restore), findsNWidgets(2));

    final deckRestore = find.byIcon(Icons.restore).last;
    await tester.tap(deckRestore);
    await tester.pumpAndSettle();

    expect(find.text('History'), findsNothing);
    expect(find.text('No deleted decks'), findsOneWidget);

    // Let the notification banner's 3-second dismiss timer complete.
    await tester.pump(const Duration(seconds: 4));
  });
}
