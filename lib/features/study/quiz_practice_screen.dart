import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';

class QuizPracticeScreen extends StatefulWidget {
  final int deckId;
  final String deckName;

  const QuizPracticeScreen({
    super.key,
    required this.deckId,
    required this.deckName,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Quiz: ${widget.deckName}',
        actions: [
          if (_isStarted)
            TextButton(
              onPressed: () => _showSummary(context),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _startQuiz(flashcards),
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
                    flashcard.answer,
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
                onPressed: _nextCard,
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

  void _startQuiz(List<dynamic> flashcards) {
    setState(() {
      _flashcards = flashcards;
      _currentIndex = 0;
      _correctCount = 0;
      _incorrectCount = 0;
      _showAnswer = false;
      _isStarted = true;
    });
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

  void _nextCard() {
    if (_currentIndex < _flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    } else {
      setState(() {
        _flashcards = [];
      });
    }
  }

  void _showSummary(BuildContext context) {
    setState(() {
      _flashcards = [];
    });
  }
}