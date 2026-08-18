import '../models/exam.dart';

/// Generates deterministic, question-type-appropriate fallback explanations
/// when AI generation fails or the AI response is invalid.
///
/// The fallback is always based on the application's stored question data —
/// it never calls the AI and never exposes internal prompts, errors, or
/// debugging information.
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
    final buffer = StringBuffer();

    if (correctAnswer.isEmpty) {
      return 'The correct answer could not be determined for this question.';
    }

    buffer.write('"$correctAnswer" is correct because it best fits the '
        'question based on the learning material.');

    if (hasAnswer && !isCorrect) {
      buffer.write(' The selected answer "$userAnswerText" does not match '
          'the correct option.');
    }

    return buffer.toString();
  }

  static String _identificationFallback({
    required String correctAnswer,
    required String userAnswerText,
    required bool isCorrect,
    required bool hasAnswer,
  }) {
    final buffer = StringBuffer();

    if (correctAnswer.isEmpty) {
      return 'The correct answer could not be determined for this question.';
    }

    buffer.write('"$correctAnswer" is correct because the description matches '
        'the concept represented by this answer.');

    if (hasAnswer && !isCorrect) {
      buffer.write(' The submitted answer "$userAnswerText" does not match '
          'the concept described in the question.');
    }

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

    final buffer = StringBuffer();

    buffer.write('The correct items are: ${correctItems.join(", ")}. ');
    buffer.write('These items represent the expected concepts identified in '
        'the learning material.');

    if (hasAnswer && !isCorrect) {
      buffer.write(' Some items may be missing or incorrect in the submitted '
          'answer.');
    }

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
}
