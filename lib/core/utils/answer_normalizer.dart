/// Centralized answer-normalization utility used by QuizSnap's grading system.
///
/// The application — not the AI — owns correctness determination. This class
/// normalizes formatting differences (capitalization, whitespace, repeated
/// spaces) so that genuinely equivalent answers are treated as equal without
/// over-normalizing distinct answers into false matches.
///
/// Usage flow (Rule 5 & Rule 6):
///
///   Question → Stored Correct Answer → AnswerNormalizer → isCorrect → AI Explanation
class AnswerNormalizer {
  AnswerNormalizer._();

  /// Normalizes a single answer string for comparison purposes.
  ///
  /// Applies:
  /// - Lowercasing
  /// - Trimming leading/trailing whitespace
  /// - Collapsing repeated internal spaces/tabs to a single space
  /// - Normalizing Unicode whitespace to ASCII space
  /// - Removing zero-width and non-breaking space characters
  static String normalize(String answer) {
    if (answer.isEmpty) return answer;

    var normalized = answer;

    // Replace non-breaking spaces, zero-width spaces, and other Unicode
    // whitespace with a standard ASCII space.
    normalized = normalized
        .replaceAll('\u00a0', ' ')
        .replaceAll('\u200b', '')
        .replaceAll('\u200c', '')
        .replaceAll('\u200d', '')
        .replaceAll('\u2009', ' ')
        .replaceAll('\u200a', ' ')
        .replaceAll('\u202f', ' ')
        .replaceAll('\u205f', ' ')
        .replaceAll('\u3000', ' ')
        .replaceAll('\t', ' ');

    // Collapse repeated spaces into a single space.
    normalized = normalized.replaceAll(RegExp(r' {2,}'), ' ');

    // Trim leading/trailing whitespace.
    normalized = normalized.trim();

    // Lowercase for case-insensitive comparison.
    normalized = normalized.toLowerCase();

    return normalized;
  }

  /// Compares two single answers for equivalence after normalization.
  static bool areEqual(String userAnswer, String correctAnswer) {
    return normalize(userAnswer) == normalize(correctAnswer);
  }

  /// Compares a user's list of answers against the correct list.
  ///
  /// Returns true only if every correct item has a matching user item and
  /// vice versa (order-independent). Each item is normalized individually.
  static bool areListsEqual(
    List<String> userAnswers,
    List<String> correctAnswers,
  ) {
    if (correctAnswers.length != userAnswers.length) return false;

    final normalizedCorrect = correctAnswers.map(normalize).toSet();
    final normalizedUser = userAnswers.map(normalize).toSet();

    return normalizedCorrect.difference(normalizedUser).isEmpty &&
        normalizedUser.difference(normalizedCorrect).isEmpty;
  }

  /// Finds which correct items are missing from the user's answers.
  ///
  /// Returns a list of the original (non-normalized) correct items that the
  /// user did not match.
  static List<String> missingItems(
    List<String> userAnswers,
    List<String> correctAnswers,
  ) {
    final normalizedUser = userAnswers.map(normalize).toSet();
    return correctAnswers
        .where((correct) => !normalizedUser.contains(normalize(correct)))
        .toList();
  }

  /// Finds which user items do not match any correct item.
  ///
  /// Returns a list of the original (non-normalized) user items that are
  /// incorrect.
  static List<String> incorrectItems(
    List<String> userAnswers,
    List<String> correctAnswers,
  ) {
    final normalizedCorrect = correctAnswers.map(normalize).toSet();
    return userAnswers
        .where((user) => !normalizedCorrect.contains(normalize(user)))
        .toList();
  }
}
