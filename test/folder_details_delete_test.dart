import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:quiz_snap/core/database/database.dart';
import 'package:quiz_snap/core/providers/database_provider.dart';
import 'package:quiz_snap/core/providers/trash_provider.dart';
import 'package:quiz_snap/core/services/trash_service.dart';
import 'package:quiz_snap/features/folders/folder_details_screen.dart';
import 'package:quiz_snap/shared/widgets/custom_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late DatabaseProvider dbProvider;
  late int folderId;
  late int deckId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase(NativeDatabase.memory());
    dbProvider = DatabaseProvider.test(database);

    folderId = await database.createFolder(
      const FoldersCompanion(name: Value('Science')),
    );
    deckId = await database.createDeck(
      DecksCompanion(
        name: const Value('Biology'),
        folderId: Value(folderId),
        color: const Value('#4CAF50'),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  Widget buildApp({required int targetFolderId}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dbProvider),
        ChangeNotifierProvider(
          create: (context) => TrashProvider(
            TrashService(
              deckRepository: dbProvider.deckRepository,
              flashcardRepository: dbProvider.flashcardRepository,
              folderRepository: dbProvider.folderRepository,
            ),
            dbEpoch: dbProvider.dbEpoch,
          ),
        ),
      ],
      child: MaterialApp(
        home: FolderDetailsScreen(folderId: targetFolderId),
      ),
    );
  }

  testWidgets('deleting a deck from folder details soft-deletes and closes success dialog on OK', (tester) async {
    await tester.pumpWidget(buildApp(targetFolderId: folderId));
    await tester.pumpAndSettle();

    // Verify the deck is listed.
    expect(find.text('Biology'), findsOneWidget);

    // Open the deck's popup menu.
    final deckCard = find.widgetWithText(CustomCard, 'Biology');
    final menu = find.descendant(of: deckCard, matching: find.byIcon(Icons.more_vert));
    await tester.tap(menu);
    await tester.pumpAndSettle();

    // Tap Delete.
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Confirm the confirmation dialog.
    expect(find.text('Move deck to Trash?'), findsOneWidget);
    await tester.tap(find.text('Move to Trash'));
    await tester.pumpAndSettle();

    // Dismiss the success dialog by tapping OK.
    expect(find.text('Deck deleted'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'OK'));
    await tester.pumpAndSettle();

    // Success dialog must be gone.
    expect(find.text('Deck deleted'), findsNothing);

    // Deck must no longer appear in the folder details list.
    expect(find.text('Biology'), findsNothing);

    // Deck must be in the trash.
    final trash = await dbProvider.deckRepository.getDeletedDecks();
    expect(trash.map((d) => d.id), contains(deckId));
  });

  testWidgets('cancelling deck delete leaves the deck in the folder', (tester) async {
    await tester.pumpWidget(buildApp(targetFolderId: folderId));
    await tester.pumpAndSettle();

    final deckCard = find.widgetWithText(CustomCard, 'Biology');
    final menu = find.descendant(of: deckCard, matching: find.byIcon(Icons.more_vert));
    await tester.tap(menu);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Dismiss the confirmation dialog by tapping Cancel.
    expect(find.text('Move deck to Trash?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Confirmation dialog must be gone and the deck must still be visible.
    expect(find.text('Move deck to Trash?'), findsNothing);
    expect(find.text('Biology'), findsOneWidget);

    // Deck must still be active.
    final active = await dbProvider.deckRepository.getDecksByFolder(folderId);
    expect(active.map((d) => d.id), contains(deckId));
  });

  testWidgets('restoring a deleted deck brings it back to the folder', (tester) async {
    // Soft-delete the deck first, then restore it and verify it reappears.
    await database.deleteDeck(deckId);

    await tester.pumpWidget(buildApp(targetFolderId: folderId));
    await tester.pumpAndSettle();

    // Folder details should show the empty state.
    expect(find.text('No decks in this folder'), findsOneWidget);

    // Restore the deck through the repository (reuses the same restore logic).
    await dbProvider.deckRepository.restoreDeck(deckId);
    dbProvider.refreshAll();

    await tester.pumpAndSettle();

    // Restored deck should be visible again in the correct folder.
    expect(find.text('Biology'), findsOneWidget);

    final active = await dbProvider.deckRepository.getDecksByFolder(folderId);
    expect(active.map((d) => d.id), contains(deckId));
  });
}
