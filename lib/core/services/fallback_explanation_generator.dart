import '../models/exam.dart';

/// Generates deterministic, question-type-appropriate fallback explanations
/// when AI generation fails or the AI response is invalid.
///
/// The fallback is always based on the application's stored question data —
/// it never calls the AI and never exposes internal prompts, errors, or
/// debugging information. When the question carries [ExamQuestion.sourceText]
/// (the original learning material), the fallback grounds the explanation in
/// that material: it pulls the sentence that defines the correct answer and
/// builds a Definition / Why it is correct / Summary structure that mirrors
/// the AI-generated explanation format.
class FallbackExplanationGenerator {
  FallbackExplanationGenerator._();

  /// Generates a fallback explanation for [question] given the student's
  /// [userAnswer] (which may be null if no answer was submitted).
  static String generate({
    required ExamQuestion question,
    UserAnswer? userAnswer,
  }) {
    final correctAnswer = question.correctAnswerText.trim();
    final userAnswerText = _userAnswerText(question, userAnswer);
    final isCorrect = userAnswer?.isCorrect ?? false;
    final hasAnswer = userAnswer != null && userAnswer.hasAnswer;

    final resolvedType = _resolveType(question);

    switch (resolvedType) {
      case QuestionType.multipleChoice:
        return _multipleChoiceFallback(
          question: question,
          correctAnswer: correctAnswer,
          userAnswerText: userAnswerText,
          isCorrect: isCorrect,
          hasAnswer: hasAnswer,
        );
      case QuestionType.identification:
        return _identificationFallback(
          question: question,
          correctAnswer: correctAnswer,
          userAnswerText: userAnswerText,
          isCorrect: isCorrect,
          hasAnswer: hasAnswer,
        );
      case QuestionType.enumeration:
        return _enumerationFallback(
          question: question,
          isCorrect: isCorrect,
          hasAnswer: hasAnswer,
        );
      case QuestionType.mixedFormat:
        return _mixedFormatFallback(
          question: question,
          correctAnswer: correctAnswer,
          userAnswerText: userAnswerText,
          isCorrect: isCorrect,
          hasAnswer: hasAnswer,
        );
    }
  }

  static String _multipleChoiceFallback({
    required ExamQuestion question,
    required String correctAnswer,
    required String userAnswerText,
    required bool isCorrect,
    required bool hasAnswer,
  }) {
    if (correctAnswer.isEmpty) {
      return 'The correct answer could not be determined for this question.';
    }

    final definition = _definitionFromSource(question, correctAnswer);
    final buffer = StringBuffer();

    if (definition != null) {
      buffer.write('Definition: $definition');
      buffer.write('\n\n');
      buffer.write('Why it is correct: "$correctAnswer" is the option that '
          'matches the learning material above.');
    } else {
      buffer.write('Definition: $correctAnswer is the correct option based on '
          'the learning material.');
      buffer.write('\n\n');
      buffer.write('Why it is correct: It best fits the question as grounded '
          'in the source material.');
    }

    if (hasAnswer && !isCorrect) {
      buffer.write(' The selected answer "$userAnswerText" does not match the '
          'correct option.');
    }

    buffer.write('\n\n');
    buffer.write('Summary: $correctAnswer is the correct answer per the '
        'learning material.');

    return buffer.toString();
  }

  static String _identificationFallback({
    required ExamQuestion question,
    required String correctAnswer,
    required String userAnswerText,
    required bool isCorrect,
    required bool hasAnswer,
  }) {
    if (correctAnswer.isEmpty) {
      return 'The correct answer could not be determined for this question.';
    }

    final definition = _definitionFromSource(question, correctAnswer);
    final buffer = StringBuffer();

    if (definition != null) {
      buffer.write('Definition: $definition');
      buffer.write('\n\n');
      buffer.write('Why it is correct: The description in the question matches '
          '"$correctAnswer" as defined in the learning material.');
    } else {
      buffer.write('Definition: "$correctAnswer" is the term that matches the '
          'description in the question, based on the learning material.');
      buffer.write('\n\n');
      buffer.write('Why it is correct: The description fits the concept '
          'represented by this answer.');
    }

    if (hasAnswer && !isCorrect) {
      buffer.write(' The submitted answer "$userAnswerText" does not match the '
          'concept described in the question.');
    }

    buffer.write('\n\n');
    buffer.write('Summary: $correctAnswer is the correct answer per the '
        'learning material.');

    return buffer.toString();
  }

  static String _enumerationFallback({
    required ExamQuestion question,
    required bool isCorrect,
    required bool hasAnswer,
  }) {
    final correctItems = question.correctAnswers ?? [];
    if (correctItems.isEmpty) {
      return 'The correct items could not be determined for this question.';
    }

    final definition = _definitionFromSource(question, correctItems.first);
    final buffer = StringBuffer();

    if (definition != null) {
      buffer.write('Definition: $definition');
      buffer.write('\n\n');
    } else {
      buffer.write('Definition: The expected items belong to the concept '
          'described in the learning material.');
      buffer.write('\n\n');
    }

    buffer.write('Why it is correct: The correct items are '
        '${correctItems.join(", ")}. These items represent the expected '
        'concepts identified in the learning material.');

    if (hasAnswer && !isCorrect) {
      buffer.write(' Some items may be missing or incorrect in the submitted '
          'answer.');
    }

    buffer.write('\n\n');
    buffer.write('Summary: ${correctItems.length} correct item(s) are '
        'expected from the learning material.');

    return buffer.toString();
  }

  static String _mixedFormatFallback({
    required ExamQuestion question,
    required String correctAnswer,
    required String userAnswerText,
    required bool isCorrect,
    required bool hasAnswer,
  }) {
    final resolvedType = _resolveType(question);

    switch (resolvedType) {
      case QuestionType.multipleChoice:
        return _multipleChoiceFallback(
          question: question,
          correctAnswer: correctAnswer,
          userAnswerText: userAnswerText,
          isCorrect: isCorrect,
          hasAnswer: hasAnswer,
        );
      case QuestionType.identification:
        return _identificationFallback(
          question: question,
          correctAnswer: correctAnswer,
          userAnswerText: userAnswerText,
          isCorrect: isCorrect,
          hasAnswer: hasAnswer,
        );
      case QuestionType.enumeration:
        return _enumerationFallback(
          question: question,
          isCorrect: isCorrect,
          hasAnswer: hasAnswer,
        );
      case QuestionType.mixedFormat:
        return _identificationFallback(
          question: question,
          correctAnswer: correctAnswer,
          userAnswerText: userAnswerText,
          isCorrect: isCorrect,
          hasAnswer: hasAnswer,
        );
    }
  }

  static QuestionType _resolveType(ExamQuestion question) {
    if (question.type != QuestionType.mixedFormat) {
      return question.type;
    }
    if (question.correctAnswers != null && question.correctAnswers!.isNotEmpty) {
      return QuestionType.enumeration;
    }
    if (question.options.length >= 2) {
      return QuestionType.multipleChoice;
    }
    return QuestionType.identification;
  }

  static String _userAnswerText(ExamQuestion question, UserAnswer? answer) {
    if (answer == null) return 'No answer';

    final index = answer.selectedAnswerIndex;
    if (index != null &&
        index >= 0 &&
        index < question.options.length) {
      return question.options[index];
    }

    final text = answer.textAnswer?.trim();
    if (text != null && text.isNotEmpty) return text;

    final list = answer.listAnswer;
    if (list != null && list.isNotEmpty) return list.join(', ');

    return 'No answer';
  }

  /// Extracts the sentence from the question's [ExamQuestion.sourceText] that
  /// best defines [term]. Returns null when no source text is available or no
  /// sentence mentions the term.
  ///
  /// The match is case-insensitive and prefers sentences that contain the term
  /// together with definition cues ("is", "are", "means", "refers to",
  /// "defined as", "describes"). Falls back to the first sentence that simply
  /// contains the term.
  static String? _definitionFromSource(ExamQuestion question, String term) {
    final source = question.sourceText?.trim();
    if (source == null || source.isEmpty) return null;
    final normalizedTerm = term.trim().toLowerCase();
    if (normalizedTerm.isEmpty) return null;

    final sentences = _splitSentences(source);
    if (sentences.isEmpty) return null;

    final definitionCues = [
      ' is ',
      ' are ',
      ' means ',
      ' refers to ',
      ' defined as ',
      ' describes ',
      ' definition of ',
      ': ',
    ];

    String? firstContaining;
    String? bestWithCue;

    for (final sentence in sentences) {
      final lower = sentence.toLowerCase();
      if (!lower.contains(normalizedTerm)) continue;

      firstContaining ??= sentence;

      for (final cue in definitionCues) {
        if (lower.contains(cue)) {
          bestWithCue ??= sentence;
          break;
        }
      }
    }

    final chosen = bestWithCue ?? firstContaining;
    return chosen != null ? _cleanSentence(chosen) : null;
  }

  /// Splits [text] into sentences on `.`, `!`, `?` followed by whitespace,
  /// preserving the punctuation. Newlines are treated as hard sentence
  /// boundaries (common in study notes / bullet material).
  static List<String> _splitSentences(String text) {
    final raw = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return raw;
  }

  static String _cleanSentence(String sentence) {
    // Collapse internal whitespace and strip stray list markers / colons that
    // would look odd when prepended with "Definition:".
    var cleaned = sentence.replaceAll(RegExp(r'\s+'), ' ').trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^[-*•]\s*'), '');
    return cleaned;
  }
}
