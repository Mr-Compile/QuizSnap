class Exam {
  final String id;
  final int deckId;
  final String deckName;
  final int totalQuestions;
  final int timeLimit; // in minutes
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final ExamStatus status;
  final int? score;
  final int? correctCount;

  Exam({
    required this.id,
    required this.deckId,
    required this.deckName,
    required this.totalQuestions,
    required this.timeLimit,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.status = ExamStatus.notStarted,
    this.score,
    this.correctCount,
  });

  Exam copyWith({
    String? id,
    int? deckId,
    String? deckName,
    int? totalQuestions,
    int? timeLimit,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    ExamStatus? status,
    int? score,
    int? correctCount,
  }) {
    return Exam(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      deckName: deckName ?? this.deckName,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      timeLimit: timeLimit ?? this.timeLimit,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      score: score ?? this.score,
      correctCount: correctCount ?? this.correctCount,
    );
  }

  double get percentage => score != null && totalQuestions > 0 
      ? (score! / totalQuestions) * 100 
      : 0.0;

  Duration get elapsed {
    if (startedAt == null) return Duration.zero;
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }

  Duration get remaining {
    if (startedAt == null) return Duration(minutes: timeLimit);
    final end = completedAt ?? DateTime.now();
    final elapsed = end.difference(startedAt!);
    final total = Duration(minutes: timeLimit);
    return total > elapsed ? total - elapsed : Duration.zero;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deckId': deckId,
      'deckName': deckName,
      'totalQuestions': totalQuestions,
      'timeLimit': timeLimit,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.toString(),
      'score': score,
      'correctCount': correctCount,
    };
  }

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      deckId: json['deckId'] as int,
      deckName: json['deckName'] as String,
      totalQuestions: json['totalQuestions'] as int,
      timeLimit: json['timeLimit'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null 
          ? DateTime.parse(json['startedAt'] as String) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      status: ExamStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ExamStatus.notStarted,
      ),
      score: json['score'] as int?,
      correctCount: json['correctCount'] as int?,
    );
  }
}

enum ExamStatus {
  notStarted,
  inProgress,
  paused,
  completed,
  abandoned,
}

extension ExamStatusExtension on ExamStatus {
  String get displayName {
    switch (this) {
      case ExamStatus.notStarted:
        return 'Not Started';
      case ExamStatus.inProgress:
        return 'In Progress';
      case ExamStatus.paused:
        return 'Paused';
      case ExamStatus.completed:
        return 'Completed';
      case ExamStatus.abandoned:
        return 'Abandoned';
    }
  }

  String get icon {
    switch (this) {
      case ExamStatus.notStarted:
        return '⏳';
      case ExamStatus.inProgress:
        return '📝';
      case ExamStatus.paused:
        return '⏸️';
      case ExamStatus.completed:
        return '✅';
      case ExamStatus.abandoned:
        return '❌';
    }
  }
}

class ExamQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;
  final int? flashcardId;

  ExamQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
    this.flashcardId,
  });

  ExamQuestion copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correctAnswerIndex,
    String? explanation,
    int? flashcardId,
  }) {
    return ExamQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      explanation: explanation ?? this.explanation,
      flashcardId: flashcardId ?? this.flashcardId,
    );
  }

  String get correctAnswer => options[correctAnswerIndex];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'flashcardId': flashcardId,
    };
  }

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      explanation: json['explanation'] as String?,
      flashcardId: json['flashcardId'] as int?,
    );
  }
}

class UserAnswer {
  final String questionId;
  final int? selectedAnswerIndex;
  final bool isCorrect;
  final DateTime answeredAt;
  final Duration timeSpent;

  UserAnswer({
    required this.questionId,
    this.selectedAnswerIndex,
    required this.isCorrect,
    required this.answeredAt,
    required this.timeSpent,
  });

  UserAnswer copyWith({
    String? questionId,
    int? selectedAnswerIndex,
    bool? isCorrect,
    DateTime? answeredAt,
    Duration? timeSpent,
  }) {
    return UserAnswer(
      questionId: questionId ?? this.questionId,
      selectedAnswerIndex: selectedAnswerIndex ?? this.selectedAnswerIndex,
      isCorrect: isCorrect ?? this.isCorrect,
      answeredAt: answeredAt ?? this.answeredAt,
      timeSpent: timeSpent ?? this.timeSpent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedAnswerIndex': selectedAnswerIndex,
      'isCorrect': isCorrect,
      'answeredAt': answeredAt.toIso8601String(),
      'timeSpent': timeSpent.inSeconds,
    };
  }

  factory UserAnswer.fromJson(Map<String, dynamic> json) {
    return UserAnswer(
      questionId: json['questionId'] as String,
      selectedAnswerIndex: json['selectedAnswerIndex'] as int?,
      isCorrect: json['isCorrect'] as bool,
      answeredAt: DateTime.parse(json['answeredAt'] as String),
      timeSpent: Duration(seconds: json['timeSpent'] as int),
    );
  }
}

class ExamResult {
  final Exam exam;
  final List<ExamQuestion> questions;
  final List<UserAnswer> answers;
  final int correctCount;
  final int incorrectCount;
  final int unansweredCount;
  final double percentage;
  final Duration totalTime;

  ExamResult({
    required this.exam,
    required this.questions,
    required this.answers,
    required this.correctCount,
    required this.incorrectCount,
    required this.unansweredCount,
    required this.percentage,
    required this.totalTime,
  });

  List<ExamQuestion> get correctQuestions {
    return questions.where((q) {
      final answer = answers.firstWhere(
        (a) => a.questionId == q.id,
        orElse: () => UserAnswer(
          questionId: q.id,
          isCorrect: false,
          answeredAt: DateTime.now(),
          timeSpent: Duration.zero,
        ),
      );
      return answer.isCorrect;
    }).toList();
  }

  List<ExamQuestion> get incorrectQuestions {
    return questions.where((q) {
      final answer = answers.firstWhere(
        (a) => a.questionId == q.id,
        orElse: () => UserAnswer(
          questionId: q.id,
          isCorrect: false,
          answeredAt: DateTime.now(),
          timeSpent: Duration.zero,
        ),
      );
      return !answer.isCorrect && answer.selectedAnswerIndex != null;
    }).toList();
  }

  List<ExamQuestion> get unansweredQuestions {
    return questions.where((q) {
      final answer = answers.firstWhere(
        (a) => a.questionId == q.id,
        orElse: () => UserAnswer(
          questionId: q.id,
          isCorrect: false,
          answeredAt: DateTime.now(),
          timeSpent: Duration.zero,
        ),
      );
      return answer.selectedAnswerIndex == null;
    }).toList();
  }

  String get grade {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  String get gradeLabel {
    switch (grade) {
      case 'A':
        return 'Excellent';
      case 'B':
        return 'Good';
      case 'C':
        return 'Satisfactory';
      case 'D':
        return 'Passing';
      default:
        return 'Needs Improvement';
    }
  }
}
