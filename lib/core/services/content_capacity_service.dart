import 'dart:math';
import '../../core/models/prompt_template.dart';
import 'document_extraction_service.dart';

/// Result of an AI generation capacity estimation.
class CapacityResult {
  /// Conservative count of usable factual units in the text.
  final int usableContent;

  /// Estimated maximum unique questions the content can support.
  final int estimatedCapacity;

  /// Number of questions the user requested.
  final int requestedCount;

  /// True when [requestedCount] is within [estimatedCapacity].
  final bool isValid;

  /// Human-readable reason when invalid.
  final String reason;

  const CapacityResult({
    required this.usableContent,
    required this.estimatedCapacity,
    required this.requestedCount,
    this.isValid = true,
    this.reason = '',
  });
}

/// Estimates how many unique questions the selected source text can reasonably
/// support, taking the selected question type into account.
///
/// The calculation uses the actual extracted content, not raw file size or
/// page count. Repeated headers, boilerplate, and whitespace should already be
/// removed by the normalization pipeline before this service is called.
class ContentCapacityService {
  ContentCapacityService._();

  /// Estimate capacity for the supplied [text], [type], and [requestedCount].
  static CapacityResult estimate(
    String text,
    PromptType type,
    int requestedCount,
  ) {
    final stats = DocumentExtractionService.getTextStatistics(text);
    final words = stats['words'] ?? 0;
    final sentences = stats['sentences'] ?? 0;
    final paragraphs = stats['paragraphs'] ?? 0;

    // Usable "facts": each sentence is a candidate, with a small boost from
    // words and paragraphs to account for lists, short headings, and
    // multi-paragraph structure.
    final usable = max(1, (words ~/ 15) + sentences + paragraphs);

    final factor = _factorForType(type, paragraphs);
    final estimated = max(1, (usable * factor).floor());

    final valid = requestedCount <= estimated;
    final reason = valid
        ? ''
        : 'This document does not contain enough usable content for '
            '$requestedCount ${_displayType(type)} questions. '
            'Estimated capacity: $estimated questions.';

    return CapacityResult(
      usableContent: usable,
      estimatedCapacity: estimated,
      requestedCount: requestedCount,
      isValid: valid,
      reason: reason,
    );
  }

  static double _factorForType(PromptType type, int paragraphs) {
    switch (type) {
      case PromptType.multipleChoice:
        // Each question needs a clear concept plus plausible distractors.
        return 0.45;
      case PromptType.identification:
        // Direct-answer questions can be derived from most sentences.
        return 0.85;
      case PromptType.enumeration:
        // Lists and groupings are less frequent; use paragraphs as a guide.
        return max(0.2, min(0.7, paragraphs / max(1, paragraphs + 5)));
      case PromptType.mixedFormat:
        // Mixed uses a blend of the above.
        return 0.6;
    }
  }

  static String _displayType(PromptType type) {
    switch (type) {
      case PromptType.multipleChoice:
        return 'multiple choice';
      case PromptType.identification:
        return 'identification';
      case PromptType.enumeration:
        return 'enumeration';
      case PromptType.mixedFormat:
        return 'mixed';
    }
  }
}
