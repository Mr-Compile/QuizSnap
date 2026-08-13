import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/question_generation_service.dart';

/// A 3D flip card for study mode.
///
/// Front = question, back = answer. Tap to flip, swipe left/right triggers
/// callbacks for quick Again/Good rating.
class FlashcardFlipCard extends StatefulWidget {
  final String question;
  final String answer;
  final bool isRevealed;
  final VoidCallback? onTap;
  final ValueChanged<DragEndDetails>? onHorizontalDragEnd;
  final double? maxWidth;

  const FlashcardFlipCard({
    super.key,
    required this.question,
    required this.answer,
    this.isRevealed = false,
    this.onTap,
    this.onHorizontalDragEnd,
    this.maxWidth,
  });

  @override
  State<FlashcardFlipCard> createState() => _FlashcardFlipCardState();
}

class _FlashcardFlipCardState extends State<FlashcardFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    if (widget.isRevealed) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant FlashcardFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed != oldWidget.isRevealed) {
      if (widget.isRevealed) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sanitizedQuestion = QuestionGenerationService.sanitizeText(widget.question);
    final sanitizedAnswer = QuestionGenerationService.sanitizeText(widget.answer);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onHorizontalDragEnd: widget.onHorizontalDragEnd,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth ?? 600,
        ),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value * pi;
            final isFront = _animation.value < 0.5;

            return Stack(
              fit: StackFit.expand,
              children: [
                _buildSide(
                  angle: angle,
                  isVisible: isFront,
                  child: _buildFace(
                    label: 'Question',
                    text: sanitizedQuestion,
                  ),
                ),
                _buildSide(
                  angle: angle - pi,
                  isVisible: !isFront,
                  child: _buildFace(
                    label: 'Answer',
                    text: sanitizedAnswer,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSide({
    required double angle,
    required bool isVisible,
    required Widget child,
  }) {
    return Opacity(
      opacity: isVisible ? 1.0 : 0.0,
      child: Transform(
        alignment: FractionalOffset.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle),
        child: child,
      ),
    );
  }

  Widget _buildFace({required String label, required String text}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
