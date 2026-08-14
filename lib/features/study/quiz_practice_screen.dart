import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/focus_mode_provider.dart';
import '../../core/utils/question_type_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';

class QuizPracticeScreen extends StatefulWidget {
  final int deckId;
  final String deckName;
  final bool shuffle;

  const QuizPracticeScreen({
    super.key,
    required this.deckId,
    required this.deckName,
    this.shuffle = true,
  });

  @override
  State<QuizPracticeScreen> createState() => _QuizPracticeScreenState();
}

class _QuizPracticeScreenState extends State<QuizPracticeScreen> {
  List<dynamic> _flashcards = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  int _incorrectCount = 0;
  bool _showAnswer = false;
  bool _isStarted = false;
  bool _shuffle = true;
  DateTime? _quizStart;
  int? _studySessionId;
  bool _isRecorded = false;
  DatabaseProvider? _dbProvider;

  @override
  void initState() {
    super.initState();
    _dbProvider = context.read<DatabaseProvider>();
    context.read<FocusModeProvider>().enterStudy();
  }

  @override
  void dispose() {
    context.read<FocusModeProvider>().exitStudy();
    // Best-effort: end the session if the user exits without finishing.
    if (!_isRecorded && _studySessionId != null && _quizStart != null) {
      final sessionId = _studySessionId!;
      final durationSeconds = DateTime.now().difference(_quizStart!).inSeconds;
      final db = _dbProvider;
      Future.microtask(() async {
        if (db == null) return;
        try {
          await db.analyticsRepository.endStudySession(
            sessionId,
            cardsStudied: 0,
            cardsCorrect: 0,
            durationSeconds: durationSeconds,
          );
          db.refreshAnalytics();
        } catch (_) {}
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Quiz: ${widget.deckName}',
        actions: [
          if (_isStarted)
            TextButton(
              onPressed: () { _showSummary(context); },
              child: const Text('Finish'),
            ),
        ],
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: dbProvider.studyRepository.getFlashcardsByDeck(widget.deckId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final flashcards = snapshot.data ?? [];

              if (!_isStarted) {
                if (flashcards.isEmpty) {
                  return EmptyState(
                    icon: Icons.credit_card,
                    title: 'No cards in this deck',
                    subtitle: 'Add some flashcards to start practicing',
                  );
                }

                return _buildStartScreen(context, flashcards);
              }

              if (_flashcards.isEmpty) {
                return _buildSummaryScreen(context);
              }

              return _buildQuizScreen(context);
            },
          );
        },
      ),
    );
  }

  Widget _buildStartScreen(BuildContext context, List<dynamic> flashcards) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.quiz,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  '${flashcards.length} cards',
                  style: AppTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Test your knowledge by answering questions from this deck.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          SwitchListTile(
            title: const Text('Shuffle cards'),
            subtitle: const Text('Randomize the order of cards for this quiz'),
            value: _shuffle,
            onChanged: (value) => setState(() => _shuffle = value),
            secondary: Icon(
              Icons.shuffle,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { _startQuiz(flashcards); },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
              ),
              child: const Text('Start Quiz'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizScreen(BuildContext context) {
    final flashcard = _flashcards[_currentIndex];
    final progress = '${_currentIndex + 1}/${_flashcards.length}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressIndicator(context, progress),
          const SizedBox(height: AppTheme.spacingLg),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question',
                  style: AppTheme.labelMedium.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  flashcard.question,
                  style: AppTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                if (_showAnswer) ...[
                  Container(
                    height: 1,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    'Answer',
                    style: AppTheme.labelMedium.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    QuestionTypeHelper.displayAnswer(flashcard),
                    style: AppTheme.headlineSmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          if (!_showAnswer) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAnswer(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                      foregroundColor: Theme.of(context).colorScheme.error,
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                    ),
                    child: const Text('I don\'t know'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAnswer(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                    ),
                    child: const Text('I know this'),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { 
                  _nextCard(); 
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                ),
                child: Text(_currentIndex < _flashcards.length - 1 ? 'Next' : 'Finish'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, String progress) {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _flashcards.length,
            backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Text(
          progress,
          style: AppTheme.labelMedium,
        ),
      ],
    );
  }

  Widget _buildSummaryScreen(BuildContext context) {
    final total = _correctCount + _incorrectCount;
    final accuracy = total > 0 ? (_correctCount / total * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'Quiz Complete!',
                  style: AppTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryStat(
                        context,
                        'Correct',
                        _correctCount.toString(),
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryStat(
                        context,
                        'Incorrect',
                        _incorrectCount.toString(),
                        Theme.of(context).colorScheme.error,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryStat(
                        context,
                        'Accuracy',
                        '$accuracy%',
                        Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
              ),
              child: const Text('Back to Study'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.headlineSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Future<void> _startQuiz(List<dynamic> flashcards) async {
    _quizStart = DateTime.now();
    final db = context.read<DatabaseProvider>();
    _studySessionId = await db.analyticsRepository.startStudySession(
      deckId: widget.deckId,
      studyMode: 'quiz',
    );
    if (!mounted) return;
    final ordered = _shuffle || widget.shuffle
        ? _shuffleList(flashcards)
        : List<dynamic>.from(flashcards);
    setState(() {
      _flashcards = ordered;
      _currentIndex = 0;
      _correctCount = 0;
      _incorrectCount = 0;
      _showAnswer = false;
      _isStarted = true;
      _isRecorded = false;
    });
  }

  List<T> _shuffleList<T>(List<T> list) {
    final shuffled = List<T>.from(list);
    final random = math.Random();
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled;
  }

  void _handleAnswer(bool correct) {
    final flashcard = _flashcards[_currentIndex];
    
    // Update card using SM-2 algorithm
    final quality = correct ? 4 : 0;
    context.read<DatabaseProvider>().studyRepository.updateCardReview(
      flashcard.id,
      quality,
    );

    setState(() {
      if (correct) {
        _correctCount++;
      } else {
        _incorrectCount++;
      }
      _showAnswer = true;
    });
  }

  Future<void> _nextCard() async {
    if (_currentIndex < _flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    } else {
      await _finishQuiz();
      if (!mounted) return;
      setState(() {
        _flashcards = [];
      });
    }
  }

  Future<void> _showSummary(BuildContext context) async {
    await _finishQuiz();
    if (!mounted) return;
    setState(() {
      _flashcards = [];
    });
  }

  Future<void> _finishQuiz() async {
    if (_isRecorded || _studySessionId == null) return;
    _isRecorded = true;
    final total = _correctCount + _incorrectCount;
    final score = total > 0 ? _correctCount / total : 0.0;
    final durationSeconds = _quizStart != null
        ? DateTime.now().difference(_quizStart!).inSeconds
        : 0;
    final db = context.read<DatabaseProvider>();
    await db.analyticsRepository.endStudySession(
      _studySessionId!,
      cardsStudied: total,
      cardsCorrect: _correctCount,
      durationSeconds: durationSeconds,
    );
    await db.analyticsRepository.createQuizResult(
      deckId: widget.deckId,
      totalQuestions: total,
      correctAnswers: _correctCount,
      score: score,
      durationSeconds: durationSeconds,
      quizType: 'practice',
    );
    db.refreshAnalytics();
  }
}