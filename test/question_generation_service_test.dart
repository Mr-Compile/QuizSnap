import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_snap/core/services/question_generation_service.dart';
import 'package:quiz_snap/core/services/question_validation_service.dart';

void main() {
  group('parseSingleMultipleChoice', () {
    test('parses normal A-D format', () {
      final result = QuestionGenerationService.parseSingleMultipleChoice('''
Question: What stores temporary working data?
A. RAM
B. ROM
C. SSD
D. HDD
Correct Answer: A
Explanation: RAM stores temporary working data.
''');

      expect(result, isNotNull);
      expect(result!.question, contains('temporary working data'));
      expect(result.options, equals(['RAM', 'ROM', 'SSD', 'HDD']));
      expect(result.correctAnswerIndex, 0);
      expect(result.answer, 'A');
      expect(result.explanation, contains('RAM stores temporary working data'));
    });

    test('parses A)-D) format', () {
      final result = QuestionGenerationService.parseSingleMultipleChoice('''
Question: Which memory is volatile?
A) RAM
B) ROM
C) SSD
D) HDD
Correct Answer: A
''');

      expect(result, isNotNull);
      expect(result!.options, equals(['RAM', 'ROM', 'SSD', 'HDD']));
      expect(result.correctAnswerIndex, 0);
    });

    test('parses lowercase labels', () {
      final result = QuestionGenerationService.parseSingleMultipleChoice('''
question: what is an input device?
a. keyboard
b. monitor
c. printer
d. speaker
correct answer: a
''');

      expect(result, isNotNull);
      expect(result!.options, hasLength(4));
      expect(result.correctAnswerIndex, 0);
    });

    test('handles extra blank lines', () {
      final result = QuestionGenerationService.parseSingleMultipleChoice('''
Question: What does CPU stand for?


A. Central Processing Unit

B. Computer Personal Unit
C. Central Processor Unit
D. Central Program Unit
Correct Answer: A
''');

      expect(result, isNotNull);
      expect(result!.options, hasLength(4));
      expect(result.options[0], 'Central Processing Unit');
      expect(result.correctAnswerIndex, 0);
    });

    test('does not treat Correct Answer as an option', () {
      final result = QuestionGenerationService.parseSingleMultipleChoice('''
Question: Which one is correct?
A. RAM
B. ROM
C. SSD
D. HDD
Correct Answer: A
''');

      expect(result, isNotNull);
      expect(result!.options, hasLength(4));
      expect(result.options, equals(['RAM', 'ROM', 'SSD', 'HDD']));
    });

    test('does not treat Explanation as an option', () {
      final result = QuestionGenerationService.parseSingleMultipleChoice('''
Question: Which is an operating system?
A. Windows
B. Stone
C. Paper
D. Cloth
Correct Answer: A
Explanation: Windows is an operating system.
''');

      expect(result, isNotNull);
      expect(result!.options, hasLength(4));
      expect(result.options, equals(['Windows', 'Stone', 'Paper', 'Cloth']));
      expect(result.explanation, contains('Windows is an operating system'));
    });

    test('ignores malformed option E', () {
      final result = QuestionGenerationService.parseSingleMultipleChoice('''
Question: What is 2+2?
A. 3
B. 4
C. 5
D. 6
E. 7
Correct Answer: B
''');

      expect(result, isNotNull);
      expect(result!.options, hasLength(4));
      expect(result.options[1], '4');
      expect(result.correctAnswerIndex, 1);
    });

    test('rejects duplicate options', () {
      final result = QuestionGenerationService.parseSingleMultipleChoice('''
Question: Pick the odd one out.
A. RAM
B. RAM
C. ROM
D. SSD
Correct Answer: C
''');

      // A duplicate leaves fewer than 4 unique labels, so the question is invalid.
      expect(result, isNull);
    });
  });

  group('MultipleChoiceQuestionValidator', () {
    test('passes a valid four-option A-D question', () {
      final warnings = MultipleChoiceQuestionValidator.validate(
        options: ['RAM', 'ROM', 'SSD', 'HDD'],
        correctAnswerIndex: 0,
        questionIndex: 0,
      );

      expect(warnings, isEmpty);
    });

    test('flags the wrong number of options', () {
      final warnings = MultipleChoiceQuestionValidator.validate(
        options: ['RAM', 'ROM', 'SSD'],
        correctAnswerIndex: 0,
        questionIndex: 0,
      );

      expect(warnings, isNotEmpty);
      expect(warnings, anyElement(contains('Expected 4 options')));
    });

    test('flags empty options', () {
      final warnings = MultipleChoiceQuestionValidator.validate(
        options: ['RAM', '', 'SSD', 'HDD'],
        correctAnswerIndex: 0,
        questionIndex: 2,
      );

      expect(warnings, anyElement(contains('empty')));
    });

    test('flags duplicate options', () {
      final warnings = MultipleChoiceQuestionValidator.validate(
        options: ['RAM', 'ROM', 'RAM', 'HDD'],
        correctAnswerIndex: 0,
        questionIndex: 1,
      );

      expect(warnings, anyElement(contains('Duplicate')));
    });

    test('flags an out-of-range correct answer', () {
      final warnings = MultipleChoiceQuestionValidator.validate(
        options: ['RAM', 'ROM', 'SSD', 'HDD'],
        correctAnswerIndex: 5,
        questionIndex: 0,
      );

      expect(warnings, anyElement(contains('A-D')));
    });
  });
}
