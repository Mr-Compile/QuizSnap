import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/explanation_sanitizer.dart';
import 'formatted_study_text.dart';

/// Shared AI explanation card used by both AI Generate Review and Exam Review.
///
/// This is the single visual identity for AI explanations across QuizSnap:
/// a lightbulb icon with the "AI Explanation" label, rendered on the
/// `tertiaryContainer` surface. Using one widget guarantees that the
/// explanation shown during AI Generate Review and the explanation shown
/// during Exam Review look identical and stay in sync.
///
/// The raw [explanation] text is run through [ExplanationSanitizer] here so
/// every call site gets the same paragraph/newline preservation without
/// duplicating sanitization logic.
class AiExplanationCard extends StatelessWidget {
  /// The raw AI explanation text (may be null or empty).
  final String? explanation;

  /// Compact mode renders the inline lightbulb box used inside question
  /// cards (AI Generate Review). Detailed mode renders a titled card suitable
  /// for the Exam Review bottom sheet / full explanation screen.
  final bool compact;

  /// Whether to show the FormattedStudyText action toolbar (copy, etc.).
  /// Defaults to false in compact mode and true in detailed mode.
  final bool? showActions;

  const AiExplanationCard({
    super.key,
    required this.explanation,
    this.compact = false,
    this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sanitized = ExplanationSanitizer.sanitize(explanation);

    if (sanitized.isEmpty) {
      return _buildUnavailable(context, colorScheme);
    }

    if (compact) {
      return _buildCompact(context, colorScheme, sanitized);
    }
    return _buildDetailed(context, colorScheme, sanitized);
  }

  Widget _buildCompact(
    BuildContext context,
    ColorScheme colorScheme,
    String sanitized,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb,
            size: 16,
            color: colorScheme.tertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FormattedStudyText(
              text: sanitized,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                  ),
              showActions: showActions ?? false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailed(
    BuildContext context,
    ColorScheme colorScheme,
    String sanitized,
  ) {
    return Semantics(
      label: 'AI explanation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'AI Explanation',
                style: AppTheme.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: FormattedStudyText(
              text: sanitized,
              style: AppTheme.bodyLarge.copyWith(
                color: colorScheme.onTertiaryContainer,
              ),
              showActions: showActions ?? true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailable(BuildContext context, ColorScheme colorScheme) {
    if (compact) {
      // In compact mode, render nothing when there is no explanation so
      // manually created flashcards do not show a broken empty box.
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'AI explanation unavailable',
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Explanation Unavailable',
              style: AppTheme.labelLarge.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'No AI explanation is stored for this question.',
              style: AppTheme.bodyMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
