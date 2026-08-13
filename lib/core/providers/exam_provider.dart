import 'package:flutter/foundation.dart';
import '../models/exam.dart';
import '../services/exam_service.dart';
import '../services/explanation_cache_service.dart';
import '../services/groq_service.dart';
import '../repositories/flashcard_repository.dart';

class ExamProvider with ChangeNotifier {
  final ExamService _examService;
  final ExplanationCacheService _cacheService;
  final GroqService? _groqService;

  Exam? _currentExam;
  List<ExamQuestion>? _currentQuestions;
  List<UserAnswer>? _currentAnswers;
  int _currentQuestionIndex = 0;
  DateTime? _currentQuestionStartTime;
  bool _isLoading = false;
  String? _errorMessage;

  ExamProvider({
    required FlashcardRepository flashcardRepository,
    required this._cacheService,
    this._groqService,
  })  : _examService = ExamService(
          flashcardRepository: flashcardRepository,
        );

  // Getters
  Exam? get currentExam => _currentExam;
  List<ExamQuestion>? get currentQuestions => _currentQuestions;
  List<UserAnswer>? get currentAnswers => _currentAnswers;
  int get currentQuestionIndex => _currentQuestionIndex;
  DateTime? get currentQuestionStartTime => _currentQuestionStartTime;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ExamQuestion? get currentQuestion {
    if (_currentQuestions == null || 
        _currentQuestionIndex >= _currentQuestions!.length) {
      return null;
    }
    return _currentQuestions![_currentQuestionIndex];
  }
  int get answeredCount => _currentAnswers?.length ?? 0;
  int get totalQuestions => _currentQuestions?.length ?? 0;
  Duration get remainingTime => _currentExam?.remaining ?? Duration.zero;
  bool get isExamExpired => remainingTime <= Duration.zero;

  // Exam creation and setup
  Future<Exam> createExam({
    required int deckId,
    required String deckName,
    required int questionCount,
    required int timeLimit,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final exam = await _examService.createExam(
        deckId: deckId,
        deckName: deckName,
        questionCount: questionCount,
        timeLimit: timeLimit,
      );

      _currentExam = exam;
      _isLoading = false;
      notifyListeners();
      return exam;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<ExamQuestion>> generateQuestions({bool shuffle = false}) async {
    if (_currentExam == null) {
      throw Exception('No active exam');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final questions = await _examService.generateExamQuestions(
        examId: _currentExam!.id,
        deckId: _currentExam!.deckId,
        questionCount: _currentExam!.totalQuestions,
        shuffle: shuffle,
      );

      _currentQuestions = questions;
      _currentQuestionIndex = 0;
      _isLoading = false;
      notifyListeners();
      return questions;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void startExam() {
    if (_currentExam == null) throw Exception('No active exam');
    
    _examService.startExam(_currentExam!.id);
    _currentExam = _examService.getActiveExam(_currentExam!.id);
    _currentQuestionStartTime = DateTime.now();
    notifyListeners();
  }

  void pauseExam() {
    if (_currentExam == null) throw Exception('No active exam');
    
    _examService.pauseExam(_currentExam!.id);
    _currentExam = _examService.getActiveExam(_currentExam!.id);
    notifyListeners();
  }

  void resumeExam() {
    if (_currentExam == null) throw Exception('No active exam');
    
    _examService.resumeExam(_currentExam!.id);
    _currentExam = _examService.getActiveExam(_currentExam!.id);
    _currentQuestionStartTime = DateTime.now();
    notifyListeners();
  }

  void submitAnswer(int selectedAnswerIndex) {
    if (_currentExam == null || currentQuestion == null) {
      throw Exception('No active exam or question');
    }

    _currentQuestionStartTime ??= DateTime.now();

    _examService.submitAnswer(
      examId: _currentExam!.id,
      questionId: currentQuestion!.id,
      selectedAnswerIndex: selectedAnswerIndex,
      questionStartTime: _currentQuestionStartTime!,
    );

    _currentAnswers = _examService.getExamAnswers(_currentExam!.id);
    notifyListeners();
  }

  void submitTextAnswer(String textAnswer) {
    if (_currentExam == null || currentQuestion == null) {
      throw Exception('No active exam or question');
    }

    _currentQuestionStartTime ??= DateTime.now();

    // Validate text answer against correct answer
    final isCorrect = _validateTextAnswer(textAnswer, currentQuestion!);

    _examService.submitTextAnswer(
      examId: _currentExam!.id,
      questionId: currentQuestion!.id,
      textAnswer: textAnswer,
      isCorrect: isCorrect,
      questionStartTime: _currentQuestionStartTime!,
    );

    _currentAnswers = _examService.getExamAnswers(_currentExam!.id);
    notifyListeners();
  }

  void submitListAnswer(List<String> listAnswer) {
    if (_currentExam == null || currentQuestion == null) {
      throw Exception('No active exam or question');
    }

    _currentQuestionStartTime ??= DateTime.now();

    // Validate list answer against correct answers
    final isCorrect = _validateListAnswer(listAnswer, currentQuestion!);

    _examService.submitListAnswer(
      examId: _currentExam!.id,
      questionId: currentQuestion!.id,
      listAnswer: listAnswer,
      isCorrect: isCorrect,
      questionStartTime: _currentQuestionStartTime!,
    );

    _currentAnswers = _examService.getExamAnswers(_currentExam!.id);
    notifyListeners();
  }

  bool _validateTextAnswer(String userAnswer, ExamQuestion question) {
    final correctAnswer = question.correctAnswer?.toLowerCase().trim() ?? '';
    final userAnswerNormalized = userAnswer.toLowerCase().trim();
    return userAnswerNormalized == correctAnswer;
  }

  bool _validateListAnswer(List<String> userAnswers, ExamQuestion question) {
    final correctAnswers = question.correctAnswers ?? [];
    if (correctAnswers.length != userAnswers.length) return false;

    final normalizedCorrect = correctAnswers.map((e) => e.toLowerCase().trim()).toSet();
    final normalizedUser = userAnswers.map((e) => e.toLowerCase().trim()).toSet();

    return normalizedCorrect.difference(normalizedUser).isEmpty;
  }

  void goToNextQuestion() {
    if (_currentQuestions == null) return;
    
    if (_currentQuestionIndex < _currentQuestions!.length - 1) {
      _currentQuestionIndex++;
      _currentQuestionStartTime = DateTime.now();
      notifyListeners();
    }
  }

  void goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      _currentQuestionStartTime = DateTime.now();
      notifyListeners();
    }
  }

  void goToQuestion(int index) {
    if (_currentQuestions == null || 
        index < 0 || 
        index >= _currentQuestions!.length) {
      return;
    }

    _currentQuestionIndex = index;
    _currentQuestionStartTime = DateTime.now();
    notifyListeners();
  }

  Future<ExamResult> completeExam() async {
    if (_currentExam == null) throw Exception('No active exam');

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _examService.completeExam(_currentExam!.id);
      _currentExam = _examService.getActiveExam(_currentExam!.id);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void abandonExam() {
    if (_currentExam == null) throw Exception('No active exam');
    
    _examService.abandonExam(_currentExam!.id);
    _currentExam = _examService.getActiveExam(_currentExam!.id);
    notifyListeners();
  }

  void clearExam() {
    if (_currentExam == null) return;
    
    _examService.clearExam(_currentExam!.id);
    _currentExam = null;
    _currentQuestions = null;
    _currentAnswers = null;
    _currentQuestionIndex = 0;
    _currentQuestionStartTime = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Explanation caching
  Future<bool> hasExplanation(String questionId) async {
    return await _cacheService.hasExplanation(questionId);
  }

  Future<String?> getExplanation(String questionId) async {
    return await _cacheService.getExplanation(questionId);
  }

  Future<void> cacheExplanation({
    required String questionId,
    required String explanation,
    required ExamQuestion question,
  }) async {
    await _cacheService.cacheExplanation(
      questionId: questionId,
      explanation: explanation,
      question: question,
    );
  }

  Future<String> generateExplanation(ExamQuestion question) async {
    // Check cache first
    final cached = await getExplanation(question.id);
    if (cached != null) {
      return cached;
    }

    if (_groqService == null || !_groqService.isInitialized) {
      throw Exception('AI service not available');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final wrongAnswers = <String>[];
      for (int i = 0; i < question.options.length; i++) {
        if (i != question.correctAnswerIndex) {
          wrongAnswers.add(question.options[i]);
        }
      }

      final explanation = await _groqService.generateExplanation(
        question: question.question,
        correctAnswer: question.correctAnswer ?? '',
        wrongAnswers: wrongAnswers,
        model: _groqService.currentModel,
      );

      // Cache the explanation
      await cacheExplanation(
        questionId: question.id,
        explanation: explanation,
        question: question,
      );

      _isLoading = false;
      notifyListeners();
      return explanation;
    } catch (e) {
      final message = e.toString().toLowerCase();
      _errorMessage = message.contains('token') || message.contains('quota') || message.contains('limit')
          ? 'AI Limit Reached. You have used today\'s AI generation limit. You can try again tomorrow or ask the administrator for additional quota.'
          : 'An error occurred while generating the explanation. Please try again.';
      _isLoading = false;
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  Future<List<CachedExplanation>> getAllCachedExplanations() async {
    return await _cacheService.getAllCachedExplanations();
  }

  Future<void> clearExpiredCache() async {
    await _cacheService.clearExpiredCache();
    notifyListeners();
  }

  Future<void> clearCache() async {
    await _cacheService.clearCache();
    notifyListeners();
  }

  Future<void> clearExplanation(String questionId) async {
    await _cacheService.clearExplanation(questionId);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Timer updates
  void updateTimer() {
    if (_currentExam != null && _currentExam!.status == ExamStatus.inProgress) {
      notifyListeners();
    }
  }
}
