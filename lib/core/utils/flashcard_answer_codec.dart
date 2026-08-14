/// Encodes and decodes MCQ options inside a flashcard answer string.
///
/// Because the Flashcards table has no dedicated question-type column,
/// MCQ options are appended to the answer using a `|||` delimiter:
///
///   `correctAnswer|||opt1||opt2||opt3||opt4||correctIndex`
///
/// Identification answers are stored as-is.
/// Enumeration answers are stored as comma-separated items (existing behaviour).
class FlashcardAnswerCodec {
  static const String _delimiter = '|||';
  static const String _optDelimiter = '||';

  /// Encodes an MCQ answer with its options and correct index.
  static String encodeMcq({
    required String correctAnswer,
    required List<String> options,
    required int correctAnswerIndex,
  }) {
    return '$correctAnswer$_delimiter${options.join(_optDelimiter)}$_optDelimiter$correctAnswerIndex';
  }

  /// Returns the display-friendly answer text, stripping any encoded options.
  static String displayAnswer(String rawAnswer) {
    final idx = rawAnswer.indexOf(_delimiter);
    if (idx == -1) return rawAnswer;
    return rawAnswer.substring(0, idx).trim();
  }

  /// Returns true if the raw answer contains encoded MCQ options.
  static bool isMcq(String rawAnswer) {
    return rawAnswer.contains(_delimiter);
  }

  /// Parses MCQ options from an encoded answer.
  /// Returns `(options, correctAnswerIndex)` or null if not MCQ.
  static ({List<String> options, int correctAnswerIndex})? decodeMcq(String rawAnswer) {
    final idx = rawAnswer.indexOf(_delimiter);
    if (idx == -1) return null;

    final encoded = rawAnswer.substring(idx + _delimiter.length);
    final parts = encoded.split(_optDelimiter);
    if (parts.length < 2) return null;

    final correctIndex = int.tryParse(parts.last) ?? 0;
    final options = parts.sublist(0, parts.length - 1);
    return (options: options, correctAnswerIndex: correctIndex);
  }
}
