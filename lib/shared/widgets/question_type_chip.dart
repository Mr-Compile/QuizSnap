import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/question_type_helper.dart';

/// A compact chip that displays a flashcard's question type with a
/// type-specific colour:
///
/// * Identification → blue
/// * Enumeration   → amber/orange
/// * Multiple Choice → purple
///
/// Uses AppTheme semantic colours so it adapts to light/dark mode.
class QuestionTypeChip extends StatelessWidget {
  final String questionType;
  final bool compact;

  const QuestionTypeChip({
    super.key,
    required this.questionType,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (color, onColor) = _colors(questionType);
    final label = compact
        ? QuestionTypeHelper.shortLabel(questionType)
        : QuestionTypeHelper.label(questionType);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Returns (background-ish colour, on-colour) for the given type.
  (Color, Color) _colors(String type) {
    switch (type) {
      case QuestionTypeHelper.multipleChoice:
        return (AppTheme.purple600, AppTheme.purple100);
      case QuestionTypeHelper.enumeration:
        return (AppTheme.orange600, AppTheme.orange100);
      case QuestionTypeHelper.identification:
      default:
        return (AppTheme.blue600, AppTheme.blue100);
    }
  }
}
