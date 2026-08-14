import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/database/database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/flashcard_reveal_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../core/providers/study_session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/flashcard_flip_card.dart';

/// Full-screen study session that uses [StudySessionController] as the
/// single source of truth. Supports resume, 3D flip, swipe ratings,
/// bookmarks, and a session completion screen.
class FlashcardStudySessionScreen extends StatefulWidget {
  final List<Flashcard> flashcards;
  final String? deckName;
  final int deckId;
  final int initialIndex;
  final bool initialRevealed;
  final bool shuffle;

  const FlashcardStudySessionScreen({
    super.key,
    required this.flashcards,
    this.deckName,
    this.deckId = 0,
    this.initialIndex = 0,
    this.initialRevealed = false,
    this.shuffle = true,
  });

  @override
  State<FlashcardStudySessionScreen> createState() =>
      _FlashcardStudySessionScreenState();
}

class _FlashcardStudySessionScreenState
    extends State<FlashcardStudySessionScreen> {
  int? _dbSessionId;
  DateTime? _dbSessionStart;
  bool _isDbSessionEnded = false;
  DatabaseProvider? _dbProvider;

  @override
  void dispose() {
    // Best-effort: end the session if the user exits without confirming
    // (e.g. system back button). We cannot await in dispose, so we fire
    // a microtask that performs the DB update.
    if (!_isDbSessionEnded && _dbSessionId != null && _dbSessionStart != null) {
      final sessionId = _dbSessionId!;
      final sessionStart = _dbSessionStart!;
      final durationSeconds = DateTime.now().difference(sessionStart).inSeconds;
      final db = _dbProvider;
      // Use a microtask to avoid async work in dispose.
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
  void initState() {
    super.initState();
    _dbProvider = context.read<DatabaseProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<FlashcardRevealProvider>().clear();
      await _startStudySession();
      if (!mounted) return;
      context.read<StudySessionController>().startSession(
        flashcards: widget.flashcards,
        deckId: widget.deckId,
        deckName: widget.deckName ?? 'Study Session',
        startIndex: widget.initialIndex,
        startRevealed: widget.initialRevealed,
        shuffle: widget.shuffle,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudySessionController>(
      builder: (context, controller, _) {
        if (!controller.hasCards) {
          return _buildEmptyState(context);
        }

        if (controller.isComplete) {
          return _buildCompletionScreen(context, controller);
        }

        final card = controller.currentCard!;
        final progress = '${controller.currentIndex + 1} / ${controller.totalCards}';

        return Scaffold(
          appBar: CustomAppBar(
            title: controller.deckName,
            actions: [
              _buildBookmarkButton(context, card),
              _buildEndSessionButton(context),
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
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: controller.progress,
                    backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FlashcardFlipCard(
                      question: card.question,
                      answer: card.answer,
                      isRevealed: controller.isRevealed,
                      onTap: controller.toggleReveal,
                      onHorizontalDragEnd: (details) => _handleSwipe(context, details, controller),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBottomControls(context, controller),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.deckName ?? 'Study Session',
      ),
      body: const Center(
        child: Text('No cards to study.'),
      ),
    );
  }

  Widget _buildCompletionScreen(BuildContext context, StudySessionController controller) {
    final summary = controller.sessionSummary;
    final minutes = summary.timeSpent.inMinutes;
    final seconds = summary.timeSpent.inSeconds % 60;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Session Complete',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
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
            _buildSummaryCard(context, summary, minutes, seconds),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton(
              onPressed: () async {
                final controller = context.read<StudySessionController>();
                final navigator = Navigator.of(context);
                await _endStudySession();
                if (!mounted) return;
                controller.endSession();
                navigator.pop();
              },
              child: const Text('Return Home'),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            OutlinedButton(
              onPressed: () async {
                final controller = context.read<StudySessionController>();
                await _endStudySession();
                if (!mounted) return;
                controller.endSession();
                _dbSessionId = null;
                _dbSessionStart = null;
                _isDbSessionEnded = false;
                controller.startSession(
                  flashcards: widget.flashcards,
                  deckId: widget.deckId,
                  deckName: widget.deckName ?? 'Study Session',
                  shuffle: widget.shuffle,
                );
                await _startStudySession();
              },
              child: const Text('Continue Studying'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, SessionSummary summary, int minutes, int seconds) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            _buildSummaryRow(context, 'Cards Studied', '${summary.cardsStudied} / ${summary.totalCards}'),
            _buildSummaryRow(context, 'Average Confidence', summary.averageConfidence.toStringAsFixed(1)),
            _buildSummaryRow(context, 'Time Spent', '${minutes}m ${seconds}s'),
            _buildSummaryRow(context, 'Due Tomorrow', summary.dueTomorrowCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, StudySessionController controller) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: controller.isRevealed
          ? _buildRatingControls(context, controller)
          : _buildConfidenceControls(context, controller),
    );
  }

  Widget _buildConfidenceControls(BuildContext context, StudySessionController controller) {
    return Column(
      key: const ValueKey('confidence'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: controller.revealCurrentCard,
            child: const Text('Tap to Reveal Answer'),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildConfidenceButton(context, 'Sure', Icons.check_circle, controller.revealCurrentCard),
            const SizedBox(width: 8),
            _buildConfidenceButton(context, 'Maybe', Icons.help, controller.revealCurrentCard),
            const SizedBox(width: 8),
            _buildConfidenceButton(context, 'No', Icons.cancel, controller.revealCurrentCard),
          ],
        ),
      ],
    );
  }

  Widget _buildConfidenceButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 64,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: AppTheme.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingControls(BuildContext context, StudySessionController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('rating'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildRatingButton(context, 'Again', colorScheme.errorContainer, colorScheme.onErrorContainer, 0, controller),
            const SizedBox(width: 8),
            _buildRatingButton(context, 'Hard', colorScheme.secondaryContainer, colorScheme.onSecondaryContainer, 2, controller),
            const SizedBox(width: 8),
            _buildRatingButton(context, 'Good', colorScheme.primaryContainer, colorScheme.onPrimaryContainer, 3, controller),
            const SizedBox(width: 8),
            _buildRatingButton(context, 'Easy', colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer, 4, controller),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.currentIndex > 0 ? controller.previousCard : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: !controller.isLastCard ? controller.nextCard : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingButton(
    BuildContext context,
    String label,
    Color background,
    Color foreground,
    int quality,
    StudySessionController controller,
  ) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: ElevatedButton(
          onPressed: () => _rateCard(context, controller, quality),
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: background.withValues(alpha: 0.5),
            disabledForegroundColor: foreground.withValues(alpha: 0.5),
            minimumSize: const Size(56, 56),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Future<void> _rateCard(BuildContext context, StudySessionController controller, int quality) async {
    HapticFeedback.mediumImpact();
    final db = context.read<DatabaseProvider>();
    await controller.rateAndAdvance(
      quality: quality,
      onPersist: (id, q) async {
        await db.studyRepository.updateCardReview(id, q);
      },
    );
  }

  void _handleSwipe(BuildContext context, DragEndDetails details, StudySessionController controller) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity == 0) return;

    if (!controller.isRevealed) {
      HapticFeedback.lightImpact();
      controller.revealCurrentCard();
      return;
    }

    if (velocity > 200) {
      _rateCard(context, controller, 3); // Good
    } else if (velocity < -200) {
      _rateCard(context, controller, 0); // Again
    }
  }

  Widget _buildBookmarkButton(BuildContext context, Flashcard card) {
    return IconButton(
      icon: Icon(
        card.isFavorite ? Icons.bookmark : Icons.bookmark_border,
        color: card.isFavorite
            ? AppTheme.amber500
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onPressed: () => _toggleBookmark(context, card),
      tooltip: card.isFavorite ? 'Remove bookmark' : 'Bookmark card',
    );
  }

  Future<void> _startStudySession() async {
    _dbSessionStart = DateTime.now();
    final db = _dbProvider ?? context.read<DatabaseProvider>();
    _dbSessionId = await db.analyticsRepository.startStudySession(
      deckId: widget.deckId == 0 ? null : widget.deckId,
      studyMode: 'review',
    );
  }

  Future<void> _endStudySession() async {
    if (_isDbSessionEnded || _dbSessionId == null || _dbSessionStart == null) {
      return;
    }
    final controller = context.read<StudySessionController>();
    final cardsStudied = controller.ratedCardIds.length;
    final cardsCorrect = controller.cardRatings.values.where((q) => q >= 3).length;
    final durationSeconds = DateTime.now().difference(_dbSessionStart!).inSeconds;
    final db = _dbProvider ?? context.read<DatabaseProvider>();
    await db.analyticsRepository.endStudySession(
      _dbSessionId!,
      cardsStudied: cardsStudied,
      cardsCorrect: cardsCorrect,
      durationSeconds: durationSeconds,
    );
    _isDbSessionEnded = true;
    db.refreshAnalytics();
  }

  Future<void> _toggleBookmark(BuildContext context, Flashcard card) async {
    final db = context.read<DatabaseProvider>();
    final updated = card.copyWith(isFavorite: !card.isFavorite);
    try {
      await db.flashcardRepository.updateFlashcard(updated);
      if (!context.mounted) return;
      await DialogService.showSuccess(
        context,
        updated.isFavorite ? 'Card bookmarked' : 'Bookmark removed',
      );
    } catch (e) {
      if (!context.mounted) return;
      await DialogService.showError(context, 'Failed to toggle bookmark: $e');
    }
  }

  Widget _buildEndSessionButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.exit_to_app),
      onPressed: () => _confirmEndSession(context),
      tooltip: 'End session',
    );
  }

  void _confirmEndSession(BuildContext context) {
    if (!context.mounted) return;
    DialogService.showConfirmation(
      context,
      'End this study session? Your progress is saved.',
      title: 'End Session',
      confirmAction: 'End',
      isDestructive: true,
      onConfirm: () async {
        final controller = context.read<StudySessionController>();
        final navigator = Navigator.of(context);
        await _endStudySession();
        if (!mounted) return;
        controller.endSession();
        navigator
          ..pop()
          ..pop();
      },
    );
  }
}
