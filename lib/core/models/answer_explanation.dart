/// Structured, student-facing explanation data returned by the AI
/// explanation pipeline.
///
/// The UI receives this object instead of a raw AI string so that it never
/// has to parse prompt content or worry about leakage. All fields are
/// determined by the application's grading system — the AI only contributes
/// the [explanation] text.
class AnswerExplanation {
  /// The correct answer as stored by QuizSnap (never overridden by the AI).
  final String correctAnswer;

  /// The student's submitted answer (may be "No answer").
  final String studentAnswer;

  /// Whether the student's answer was correct, as determined by QuizSnap's
  /// grading system — never by the AI.
  final bool isCorrect;

  /// The clean, sanitized, student-facing explanation text.
  final String explanation;

  /// Whether [explanation] came from the fallback generator rather than the AI.
  final bool isFallback;

  const AnswerExplanation({
    required this.correctAnswer,
    required this.studentAnswer,
    required this.isCorrect,
    required this.explanation,
    this.isFallback = false,
  });

  AnswerExplanation copyWith({
    String? correctAnswer,
    String? studentAnswer,
    bool? isCorrect,
    String? explanation,
    bool? isFallback,
  }) {
    return AnswerExplanation(
      correctAnswer: correctAnswer ?? this.correctAnswer,
      studentAnswer: studentAnswer ?? this.studentAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      explanation: explanation ?? this.explanation,
      isFallback: isFallback ?? this.isFallback,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'correctAnswer': correctAnswer,
      'studentAnswer': studentAnswer,
      'isCorrect': isCorrect,
      'explanation': explanation,
      'isFallback': isFallback,
    };
  }

  factory AnswerExplanation.fromJson(Map<String, dynamic> json) {
    return AnswerExplanation(
      correctAnswer: json['correctAnswer'] as String? ?? '',
      studentAnswer: json['studentAnswer'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
      isFallback: json['isFallback'] as bool? ?? false,
    );
  }
}
