import 'dart:math';
import '../database/database.dart';
import '../models/exam.dart';
import '../repositories/flashcard_repository.dart';
import 'question_validation_service.dart';

class ExamService {
  final FlashcardRepository _flashcardRepository;
  final Map<String, Exam> _activeExams = {};
  final Map<String, List<ExamQuestion>> _examQuestions = {};
  final Map<String, List<UserAnswer>> _examAnswers = {};

  ExamService({
    required this._flashcardRepository,
  });

  Exam? getActiveExam(String examId) => _activeExams[examId];
  List<ExamQuestion>? getExamQuestions(String examId) => _examQuestions[examId];
  List<UserAnswer>? getExamAnswers(String examId) => _examAnswers[examId];

  Future<Exam> createExam({
    required int deckId,
    required String deckName,
    required int questionCount,
    required int timeLimit,
  }) async {
    final flashcards = await _flashcardRepository.getFlashcardsByDeck(deckId);

    if (flashcards.length < questionCount) {
      throw Exception(
        'Not enough flashcards in deck. Available: ${flashcards.length}, Requested: $questionCount',
      );
    }

    final examId = _generateExamId();
    final exam = Exam(
      id: examId,
      deckId: deckId,
      deckName: deckName,
      totalQuestions: questionCount,
      timeLimit: timeLimit,
      createdAt: DateTime.now(),
      status: ExamStatus.notStarted,
    );

    _activeExams[examId] = exam;
    return exam;
  }

  Future<List<ExamQuestion>> generateExamQuestions({
    required String examId,
    required int deckId,
    required int questionCount,
    bool shuffle = false,
  }) async {
    final flashcards = await _flashcardRepository.getFlashcardsByDeck(deckId);
    final pool = _shuffleList(flashcards);
    final selectedFlashcards = pool.take(questionCount).toList();
    final ordered = shuffle ? _shuffleList(selectedFlashcards) : selectedFlashcards;

    final questions = _generateBasicQuestions(ordered);
    _examQuestions[examId] = questions;
    return questions;
  }

  List<ExamQuestion> _generateBasicQuestions(List<Flashcard> flashcards) {
    final otherAnswers = flashcards
        .map((f) => f.answer.trim())
        .where((a) => a.isNotEmpty)
        .toList();

    return flashcards.asMap().entries.map((entry) {
      final index = entry.key;
      final flashcard = entry.value;
      final answer = flashcard.answer.trim();

      String? correctAnswer;
      List<String>? correctAnswersList;

      if (answer.isNotEmpty) {
        final items = EnumerationFormatter.splitItems(answer);
        if (items.length > 1) {
          correctAnswersList = items;
        } else {
          correctAnswer = answer;
        }
      }

      // Build a multiple-choice option only for short single answers with enough distractors.
      if (correctAnswer != null && correctAnswer.length <= 40) {
        final correct = correctAnswer;
        final distractorPool = otherAnswers
            .where((a) => a.toLowerCase() != correct.toLowerCase())
            .toSet()
            .toList();

        final distractors = _shuffleList(distractorPool).take(3).toList();

        if (distractors.length == 3) {
          final options = _shuffleList([correct, ...distractors]);
          final correctAnswerIndex = options.indexWhere(
            (o) => o.toLowerCase() == correct.toLowerCase(),
          );

          return ExamQuestion(
            id: 'q_${flashcard.id}_$index',
            question: flashcard.question,
            type: QuestionType.multipleChoice,
            options: options,
            correctAnswerIndex: correctAnswerIndex,
            flashcardId: flashcard.id,
          );
        }
      }

      final questionType = correctAnswersList != null && correctAnswersList.length > 1
          ? QuestionType.enumeration
          : QuestionType.identification;

      return ExamQuestion(
        id: 'q_${flashcard.id}_$index',
        question: flashcard.question,
        type: questionType,
        correctAnswer: correctAnswer,
        correctAnswers: correctAnswersList,
        flashcardId: flashcard.id,
      );
    }).toList();
  }

  void startExam(String examId) {
    final exam = _activeExams[examId];
    if (exam == null) throw Exception('Exam not found');

    _activeExams[examId] = exam.copyWith(
      startedAt: DateTime.now(),
      status: ExamStatus.inProgress,
    );
    _examAnswers[examId] = [];
  }

  void pauseExam(String examId) {
    final exam = _activeExams[examId];
    if (exam == null) throw Exception('Exam not found');

    _activeExams[examId] = exam.copyWith(
      status: ExamStatus.paused,
    );
  }

  void resumeExam(String examId) {
    final exam = _activeExams[examId];
    if (exam == null) throw Exception('Exam not found');

    // Adjust start time to account for pause duration
    final now = DateTime.now();
    final elapsedBeforePause = exam.elapsed;
    final newStartTime = now.subtract(elapsedBeforePause);

    _activeExams[examId] = exam.copyWith(
      startedAt: newStartTime,
      status: ExamStatus.inProgress,
    );
  }

  void submitAnswer({
    required String examId,
    required String questionId,
    required int selectedAnswerIndex,
    required DateTime questionStartTime,
  }) {
    final questions = _examQuestions[examId];
    if (questions == null) throw Exception('Questions not found');

    final question = questions.firstWhere((q) => q.id == questionId);
    final isCorrect = selectedAnswerIndex == question.correctAnswerIndex;
    final timeSpent = DateTime.now().difference(questionStartTime);

    final answer = UserAnswer(
      questionId: questionId,
      selectedAnswerIndex: selectedAnswerIndex,
      isCorrect: isCorrect,
      answeredAt: DateTime.now(),
      timeSpent: timeSpent,
    );

    final answers = _examAnswers[examId] ?? [];
    final existingIndex = answers.indexWhere((a) => a.questionId == questionId);

    if (existingIndex >= 0) {
      answers[existingIndex] = answer;
    } else {
      answers.add(answer);
    }

    _examAnswers[examId] = answers;
  }

  void submitTextAnswer({
    required String examId,
    required String questionId,
    required String textAnswer,
    required bool isCorrect,
    required DateTime questionStartTime,
  }) {
    final timeSpent = DateTime.now().difference(questionStartTime);

    final answer = UserAnswer(
      questionId: questionId,
      textAnswer: textAnswer,
      isCorrect: isCorrect,
      answeredAt: DateTime.now(),
      timeSpent: timeSpent,
    );

    final answers = _examAnswers[examId] ?? [];
    final existingIndex = answers.indexWhere((a) => a.questionId == questionId);

    if (existingIndex >= 0) {
      answers[existingIndex] = answer;
    } else {
      answers.add(answer);
    }

    _examAnswers[examId] = answers;
  }

  void submitListAnswer({
    required String examId,
    required String questionId,
    required List<String> listAnswer,
    required bool isCorrect,
    required DateTime questionStartTime,
  }) {
    final timeSpent = DateTime.now().difference(questionStartTime);

    final answer = UserAnswer(
      questionId: questionId,
      listAnswer: listAnswer,
      isCorrect: isCorrect,
      answeredAt: DateTime.now(),
      timeSpent: timeSpent,
    );

    final answers = _examAnswers[examId] ?? [];
    final existingIndex = answers.indexWhere((a) => a.questionId == questionId);

    if (existingIndex >= 0) {
      answers[existingIndex] = answer;
    } else {
      answers.add(answer);
    }

    _examAnswers[examId] = answers;
  }

  Future<ExamResult> completeExam(String examId) async {
    final exam = _activeExams[examId];
    final questions = _examQuestions[examId];
    final answers = _examAnswers[examId];

    if (exam == null || questions == null || answers == null) {
      throw Exception('Exam data not found');
    }

    final correctCount = answers.where((a) => a.isCorrect).length;
    final incorrectCount = answers.where((a) => !a.isCorrect && a.hasAnswer).length;
    final unansweredCount = questions.where((q) {
      final answer = answers.firstWhere(
        (a) => a.questionId == q.id,
        orElse: () => UserAnswer(
          questionId: q.id,
          isCorrect: false,
          answeredAt: DateTime.now(),
          timeSpent: Duration.zero,
        ),
      );
      return !answer.hasAnswer;
    }).length;
    final percentage = questions.isNotEmpty
        ? (correctCount / questions.length) * 100
        : 0.0;

    final completedExam = exam.copyWith(
      completedAt: DateTime.now(),
      status: ExamStatus.completed,
      score: correctCount,
      correctCount: correctCount,
    );

    _activeExams[examId] = completedExam;

    return ExamResult(
      exam: completedExam,
      questions: questions,
      answers: answers,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      unansweredCount: unansweredCount,
      percentage: percentage,
      totalTime: completedExam.elapsed,
    );
  }

  void abandonExam(String examId) {
    final exam = _activeExams[examId];
    if (exam == null) throw Exception('Exam not found');

    _activeExams[examId] = exam.copyWith(
      status: ExamStatus.abandoned,
      completedAt: DateTime.now(),
    );
  }

  void clearExam(String examId) {
    _activeExams.remove(examId);
    _examQuestions.remove(examId);
    _examAnswers.remove(examId);
  }

  List<T> _shuffleList<T>(List<T> list) {
    final shuffled = List<T>.from(list);
    final random = Random();
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled;
  }

  String _generateExamId() {
    return 'exam_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  int getAnsweredCount(String examId) {
    return _examAnswers[examId]?.length ?? 0;
  }

  int getTotalQuestions(String examId) {
    return _examQuestions[examId]?.length ?? 0;
  }

  Duration getRemainingTime(String examId) {
    final exam = _activeExams[examId];
    return exam?.remaining ?? Duration.zero;
  }

  bool isExamExpired(String examId) {
    return getRemainingTime(examId) <= Duration.zero;
  }
}
