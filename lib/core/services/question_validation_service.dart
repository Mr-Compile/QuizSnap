/// Validates and formats AI-generated answers so they stay useful for
/// flashcards and study sessions.
class IdentificationAnswerValidator {
  static const int maxWords = 4;

  /// Returns a list of validation warnings for an identification answer.
  static List<String> validate(String answer, int questionIndex) {
    final issues = <String>[];
    final trimmed = answer.trim();
    if (trimmed.isEmpty) {
      issues.add('Question ${questionIndex + 1}: Identification answer is empty');
      return issues;
    }
    final wordCount = _wordCount(trimmed);
    if (wordCount > maxWords) {
      issues.add(
        'Question ${questionIndex + 1}: Identification answer is $wordCount words long (max $maxWords)',
      );
    }
    if (RegExp(r'^[Aa]n?\s').hasMatch(trimmed)) {
      issues.add(
        'Question ${questionIndex + 1}: Identification answer should not include leading articles',
      );
    }
    return issues;
  }

  /// Strips leading articles and trims an identification answer.
  static String format(String answer) {
    return answer
        .replaceAll(RegExp(r'^(the|a|an)\s+', caseSensitive: false), '')
        .trim();
  }

  static int _wordCount(String text) {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
}

/// Formats enumeration answers into a concise list of short items.
class EnumerationFormatter {
  static const int maxWordsPerItem = 3;

  /// Splits an answer string into normalized items and returns a list of
  /// validation warnings.
  static List<String> validate(String answer, int questionIndex) {
    final issues = <String>[];
    final trimmed = answer.trim();
    if (trimmed.isEmpty) {
      issues.add('Question ${questionIndex + 1}: Enumeration answer is empty');
      return issues;
    }
    final items = _splitItems(trimmed);
    if (items.isEmpty) {
      issues.add('Question ${questionIndex + 1}: Enumeration has no items');
      return issues;
    }
    for (final item in items) {
      final words = _wordCount(item);
      if (words > maxWordsPerItem) {
        issues.add(
          'Question ${questionIndex + 1}: Enumeration item "$item" is $words words (max $maxWordsPerItem)',
        );
      }
    }
    return issues;
  }

  /// Returns the answer as a cleaned comma-separated string.
  static String format(String answer) {
    final items = _splitItems(answer);
    return items.join(', ');
  }

  static List<String> _splitItems(String answer) {
    return answer
        .split(RegExp(r'\n|,(?![^\(]*\))'))
        .map((s) => s.replaceAll(RegExp(r'^\s*[\d•\-\*\.\)]+\s*'), '').trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static int _wordCount(String text) {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
}

/// Validates multiple-choice questions before they are saved.
class MultipleChoiceQuestionValidator {
  static const String _labels = 'ABCD';

  /// Returns a list of validation warnings for a multiple-choice question.
  static List<String> validate({
    required List<String> options,
    required int correctAnswerIndex,
    required int questionIndex,
    String? answer,
  }) {
    final issues = <String>[];

    if (options.length != 4) {
      issues.add('Question ${questionIndex + 1}: Expected 4 options (A-D), found ${options.length}');
    }

    if (options.any((o) => o.trim().isEmpty)) {
      issues.add('Question ${questionIndex + 1}: One or more options are empty');
    }

    final seen = <String>{};
    for (final option in options) {
      final key = option.toLowerCase().trim();
      if (seen.contains(key)) {
        issues.add('Question ${questionIndex + 1}: Duplicate options detected');
        break;
      }
      seen.add(key);
    }

    if (correctAnswerIndex < 0 || correctAnswerIndex >= 4) {
      issues.add('Question ${questionIndex + 1}: Correct answer must be one of A-D');
    }

    if (answer != null && answer.isNotEmpty) {
      final normalized = answer.trim().toUpperCase().replaceAll(RegExp(r'[).]+$'), '');
      if (!_labels.contains(normalized)) {
        issues.add('Question ${questionIndex + 1}: Correct answer "$answer" is not A-D');
      }
    }

    return issues;
  }

  /// Attempts to repair a malformed multiple-choice option list.
  ///
  /// Returns the repaired list and a clamped correct-answer index.
  static ({List<String> options, int correctAnswerIndex, List<String> warnings}) repair({
    required List<String> options,
    required int correctAnswerIndex,
    required int questionIndex,
    String? answer,
  }) {
    final cleaned = options
        .map((o) => o.replaceFirst(RegExp(r'^\s*[A-Da-d][).\-]?\s*'), '').trim())
        .where((o) => o.isNotEmpty)
        .toList();

    final valid = <String>[];
    final seen = <String>{};
    for (final option in cleaned) {
      final key = option.toLowerCase().trim();
      if (seen.contains(key)) continue;
      seen.add(key);
      valid.add(option);
    }

    final repairedOptions = valid.take(4).toList();
    final warnings = validate(
      options: repairedOptions,
      correctAnswerIndex: correctAnswerIndex,
      questionIndex: questionIndex,
      answer: answer,
    );

    int repairedIndex = correctAnswerIndex;
    if (repairedIndex < 0 || repairedIndex >= repairedOptions.length) {
      final answerLetter = (answer ?? '').trim().toUpperCase().replaceAll(RegExp(r'[).]+$'), '');
      if (answerLetter.isNotEmpty && _labels.contains(answerLetter[0])) {
        repairedIndex = _labels.indexOf(answerLetter[0]);
      } else {
        repairedIndex = 0;
      }
    }
    if (repairedIndex >= repairedOptions.length) {
      repairedIndex = 0;
    }

    return (
      options: repairedOptions,
      correctAnswerIndex: repairedIndex,
      warnings: warnings,
    );
  }
}
