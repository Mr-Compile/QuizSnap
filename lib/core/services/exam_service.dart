import 'dart:math';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/exam.dart';
import '../repositories/flashcard_repository.dart';
import 'groq_service.dart';

class ExamService {
  final FlashcardRepository _flashcardRepository;
  final GroqService? _groqService;
  final Map<String, Exam> _activeExams = {};
  final Map<String, List<ExamQuestion>> _examQuestions = {};
  final Map<String, List<UserAnswer>> _examAnswers = {};

  ExamService({
    required FlashcardRepository flashcardRepository,
    GroqService? groqService,
  })  : _flashcardRepository = flashcardRepository,
        _groqService = groqService;

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
    bool useAI = false,
  }) async {
    final flashcards = await _flashcardRepository.getFlashcardsByDeck(deckId);
    final selectedFlashcards = _shuffleList(flashcards).take(questionCount).toList();

    List<ExamQuestion> questions;

    if (useAI && _groqService != null && _groqService!.isInitialized) {
      questions = await _generateAIQuestions(selectedFlashcards);
    } else {
      questions = _generateBasicQuestions(selectedFlashcards);
    }

    _examQuestions[examId] = questions;
    return questions;
  }

  List<ExamQuestion> _generateBasicQuestions(List<Flashcard> flashcards) {
    return flashcards.asMap().entries.map((entry) {
      final index = entry.key;
      final flashcard = entry.value;

      // Generate multiple choice options from other flashcards
      final otherAnswers = flashcards
          .where((f) => f.id != flashcard.id)
          .map((f) => f.answer)
          .toList();

      final shuffledAnswers = _shuffleList(otherAnswers);
      final wrongAnswers = shuffledAnswers.take(3).toList();

      // Ensure we have enough options
      final options = _shuffleList([
        flashcard.answer,
        ...wrongAnswers,
        if (wrongAnswers.length < 3) ...List.generate(
          3 - wrongAnswers.length,
          (i) => 'Distractor option ${i + 1}',
        ),
      ]);

      final correctAnswerIndex = options.indexOf(flashcard.answer);

      return ExamQuestion(
        id: 'q_${flashcard.id}_$index',
        question: flashcard.question,
        options: options,
        correctAnswerIndex: correctAnswerIndex,
        flashcardId: flashcard.id,
      );
    }).toList();
  }

  Future<List<ExamQuestion>> _generateAIQuestions(List<Flashcard> flashcards) async {
    final questions = <ExamQuestion>[];

    for (final flashcard in flashcards) {
      try {
        final prompt = '''Generate a multiple choice question based on this flashcard:

Question: ${flashcard.question}
Answer: ${flashcard.answer}

Create 4 options (A, B, C, D) where only one is correct. Format your response as:
QUESTION: [your question text]
A: [option A]
B: [option B]
C: [option C]
D: [option D]
CORRECT: [A, B, C, or D]''';

        final response = await _groqService!.generateQuestions(
          content: prompt,
          template: null,
          questionCount: 1,
        );

        final parsedQuestion = _parseAIQuestion(response, flashcard);
        if (parsedQuestion != null) {
          questions.add(parsedQuestion);
        } else {
          // Fallback to basic question generation
          questions.add(_createBasicQuestion(flashcard, questions.length));
        }
      } catch (e) {
        // Fallback to basic question generation on error
        questions.add(_createBasicQuestion(flashcard, questions.length));
      }
    }

    return questions;
  }

  ExamQuestion? _parseAIQuestion(String response, Flashcard flashcard) {
    try {
      final lines = response.split('\n');
      String? question;
      final options = <String>[];
      String? correctLetter;

      for (final line in lines) {
        if (line.startsWith('QUESTION:')) {
          question = line.substring(9).trim();
        } else if (line.startsWith('A:') || line.startsWith('B:') || 
                   line.startsWith('C:') || line.startsWith('D:')) {
          options.add(line.substring(2).trim());
        } else if (line.startsWith('CORRECT:')) {
          correctLetter = line.substring(8).trim();
        }
      }

      if (question == null || options.length != 4 || correctLetter == null) {
        return null;
      }

      final correctIndex = {'A': 0, 'B': 1, 'C': 2, 'D': 3}[correctLetter];
      if (correctIndex == null) return null;

      return ExamQuestion(
        id: 'ai_${flashcard.id}_${DateTime.now().millisecondsSinceEpoch}',
        question: question,
        options: options,
        correctAnswerIndex: correctIndex,
        flashcardId: flashcard.id,
      );
    } catch (e) {
      return null;
    }
  }

  ExamQuestion _createBasicQuestion(Flashcard flashcard, int index) {
    // Simple fallback - use the flashcard as-is
    final options = [
      flashcard.answer,
      'Incorrect option 1',
      'Incorrect option 2',
      'Incorrect option 3',
    ];

    return ExamQuestion(
      id: 'fallback_${flashcard.id}_$index',
      question: flashcard.question,
      options: options,
      correctAnswerIndex: 0,
      flashcardId: flashcard.id,
    );
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

  Future<ExamResult> completeExam(String examId) async {
    final exam = _activeExams[examId];
    final questions = _examQuestions[examId];
    final answers = _examAnswers[examId];

    if (exam == null || questions == null || answers == null) {
      throw Exception('Exam data not found');
    }

    final correctCount = answers.where((a) => a.isCorrect).length;
    final incorrectCount = answers.where((a) => !a.isCorrect && a.selectedAnswerIndex != null).length;
    final unansweredCount = questions.length - answers.length;
    final percentage = questions.length > 0 
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
