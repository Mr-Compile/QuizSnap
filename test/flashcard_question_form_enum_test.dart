import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_snap/core/utils/question_type_helper.dart';
import 'package:quiz_snap/shared/widgets/flashcard_question_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Manual enumeration creation: add, delete, save', (
    WidgetTester tester,
  ) async {
    FlashcardFormData? submitted;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SingleChildScrollView(
            child: FlashcardQuestionForm(
              submitLabel: 'Save',
              onSubmit: (data) => submitted = data,
            ),
          ),
        ),
      ),
    );

    // Initial frame.
    await tester.pump(const Duration(milliseconds: 100));

    // Switch to Enumeration.
    await tester.tap(find.text('Enum'));
    await tester.pump(const Duration(milliseconds: 300));

    // Enter the question.
    await tester.enterText(find.byType(TextFormField).first, 'Name three colors.');
    await tester.pump(const Duration(milliseconds: 100));

    // Fill Answer 1.
    await tester.enterText(find.widgetWithText(TextFormField, 'Answer 1'), 'Red');
    await tester.pump(const Duration(milliseconds: 100));

    // Add Answer 2 and fill.
    await tester.tap(find.text('Add Answer'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.widgetWithText(TextFormField, 'Answer 2'), 'Blue');
    await tester.pump(const Duration(milliseconds: 100));

    // Add Answer 3 and fill.
    await tester.tap(find.text('Add Answer'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.widgetWithText(TextFormField, 'Answer 3'), 'Yellow');
    await tester.pump(const Duration(milliseconds: 100));

    // Delete the second answer (Blue).
    await tester.tap(find.byIcon(Icons.delete_outline).at(1));
    await tester.pump(const Duration(milliseconds: 100));

    // Add a replacement Answer 3.
    await tester.tap(find.text('Add Answer'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.widgetWithText(TextFormField, 'Answer 3'), 'Green');
    await tester.pump(const Duration(milliseconds: 100));

    // Scroll to and tap Save.
    await tester.ensureVisible(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(submitted, isNotNull);
    expect(submitted!.questionType, QuestionTypeHelper.enumeration);
    expect(submitted!.question, 'Name three colors.');
    expect(submitted!.answer, 'Red, Yellow, Green');
    expect(
      QuestionTypeHelper.decodeEnumerationItems(submitted!.enumerationItemsJson),
      ['Red', 'Yellow', 'Green'],
    );
  });

  testWidgets('Empty enumeration answer is rejected', (
    WidgetTester tester,
  ) async {
    FlashcardFormData? submitted;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SingleChildScrollView(
            child: FlashcardQuestionForm(
              submitLabel: 'Save',
              onSubmit: (data) => submitted = data,
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Enum'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextFormField).first, 'Name one color.');
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Add Answer'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.widgetWithText(TextFormField, 'Answer 1'), 'Red');
    await tester.pump(const Duration(milliseconds: 100));

    await tester.ensureVisible(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(submitted, isNull);
    expect(find.text('Answer cannot be empty'), findsOneWidget);
  });
}
