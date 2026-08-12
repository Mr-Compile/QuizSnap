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
