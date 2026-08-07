import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import 'rate_card_bottom_sheet.dart';

class FlashcardCardScreen extends StatefulWidget {
  final List<dynamic> flashcards;
  final int currentIndex;
  final Function(int) onCardRated;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const FlashcardCardScreen({
    super.key,
    required this.flashcards,
    required this.currentIndex,
    required this.onCardRated,
    this.onPrevious,
    this.onNext,
  });

  @override
  State<FlashcardCardScreen> createState() => _FlashcardCardScreenState();
}

class _FlashcardCardScreenState extends State<FlashcardCardScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  bool _isAnswerRevealed = false;

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flashcard = widget.flashcards[widget.currentIndex];
    final progress = '${widget.currentIndex + 1}/${widget.flashcards.length}';

    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            controller: _swiperController,
            cardsCount: widget.flashcards.length,
            initialIndex: widget.currentIndex,
            onSwipe: _onSwipe,
            isLoop: false,
            onSwipeDirectionChange: _onSwipeDirectionChange,
            cardBuilder: (context, index, percentThresholds, direction) {
              final card = widget.flashcards[index];
              return _buildFlashcard(context, card, index);
            },
          ),
        ),
        _buildProgressIndicator(context, progress),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildFlashcard(BuildContext context, dynamic flashcard, int index) {
    final isCurrentCard = index == widget.currentIndex;
    
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAnswerRevealed = !_isAnswerRevealed),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_isAnswerRevealed) ...[
                      Container(
                        width: double.infinity,
                        height: 2,
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingLg),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
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
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          if (!_isAnswerRevealed)
            ElevatedButton.icon(
              onPressed: () => setState(() => _isAnswerRevealed = true),
              icon: const Icon(Icons.visibility),
              label: const Text('Show Answer'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, String progress) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: (widget.currentIndex + 1) / widget.flashcards.length,
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
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        children: [
          if (widget.onPrevious != null && widget.currentIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onPrevious,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
            ),
          if (widget.onPrevious != null && widget.currentIndex > 0)
            const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: ElevatedButton(
              onPressed: _isAnswerRevealed ? () => _showRateBottomSheet(context) : null,
              child: const Text('Rate Card'),
            ),
          ),
        ],
      ),
    );
  }

  void _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (direction == CardSwiperDirection.right) {
      // Swipe right = easy/good
      widget.onCardRated(4);
    } else if (direction == CardSwiperDirection.left) {
      // Swipe left = again/hard
      widget.onCardRated(2);
    }
  }

  void _onSwipeDirectionChange(CardSwiperDirection? direction) {
    // Handle swipe direction changes if needed
  }

  void _showRateBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => RateCardBottomSheet(
        onRated: (quality) {
          Navigator.of(context).pop();
          widget.onCardRated(quality);
        },
      ),
    );
  }
}