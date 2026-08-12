import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/database/database.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import 'flashcard_card_screen.dart';

/// Full-screen study session that cycles through a list of flashcards,
/// persists SM-2 ratings, handles bookmarks, and supports delete/restore.
class FlashcardStudySessionScreen extends StatefulWidget {
  final List<Flashcard> flashcards;
  final String? deckName;
  final int initialIndex;

  const FlashcardStudySessionScreen({
    super.key,
    required this.flashcards,
    this.deckName,
    this.initialIndex = 0,
  });

  @override
  State<FlashcardStudySessionScreen> createState() =>
      _FlashcardStudySessionScreenState();
}

class _FlashcardStudySessionScreenState
    extends State<FlashcardStudySessionScreen> {
  late List<Flashcard> _flashcards;
  late int _currentIndex;
  int _correctCount = 0;
  int _incorrectCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _flashcards = List.from(widget.flashcards);
    _currentIndex = widget.initialIndex >= 0 &&
            widget.initialIndex < _flashcards.length
        ? widget.initialIndex
        : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_flashcards.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(
          title: widget.deckName ?? 'Study Session',
        ),
        body: const Center(
          child: Text('No cards to study.'),
        ),
      );
    }

    if (_currentIndex >= _flashcards.length) {
      return _buildSummaryScreen(context);
    }

    final progress =
        '${_currentIndex + 1} / ${_flashcards.length}';

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.deckName ?? 'Study Session',
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingMd),
              child: Text(
                progress,
                style: AppTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _flashcards.length,
          ),
          Expanded(
            child: FlashcardCardScreen(
              flashcards: _flashcards,
              currentIndex: _currentIndex,
              onCardRated: _onCardRated,
              onPrevious: _currentIndex > 0 ? _onPrevious : null,
              onNext: _currentIndex < _flashcards.length - 1
                  ? _onNext
                  : null,
              onDelete: () => _onDelete(_flashcards[_currentIndex]),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildSummaryScreen(BuildContext context) {
    final total = _correctCount + _incorrectCount;
    final accuracy = total > 0 ? (_correctCount / total * 100).round() : 0;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Session Complete',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.emoji_events,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Review Complete!',
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Row(
              children: [
                Expanded(
                  child: _buildStat(context, 'Correct', _correctCount, Colors.green),
                ),
                Expanded(
                  child: _buildStat(context, 'Incorrect', _incorrectCount, Colors.red),
                ),
                Expanded(
                  child: _buildStat(context, 'Accuracy', '$accuracy%', Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Study'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
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

  Future<void> _onCardRated(int quality) async {
    final card = _flashcards[_currentIndex];

    setState(() => _isLoading = true);

    try {
      final db = context.read<DatabaseProvider>();
      await db.studyRepository.updateCardReview(card.id, quality);

      if (quality >= 3) {
        _correctCount++;
      } else {
        _incorrectCount++;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_currentIndex < _flashcards.length - 1) {
            _currentIndex++;
          } else {
            _currentIndex = _flashcards.length;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save rating: $e')),
        );
      }
    }
  }

  void _onPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _onNext() {
    // Skip current card without rating.
    if (_currentIndex < _flashcards.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  Future<void> _onDelete(Flashcard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: const Text('Delete this card from the deck?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final db = context.read<DatabaseProvider>();
      await db.flashcardRepository.deleteFlashcard(card.id);

      if (mounted) {
        setState(() {
          _flashcards.removeAt(_currentIndex);
          if (_currentIndex >= _flashcards.length && _flashcards.isNotEmpty) {
            _currentIndex = _flashcards.length - 1;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }
}
