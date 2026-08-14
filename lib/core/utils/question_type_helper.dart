import 'dart:convert';
import '../database/database.dart';
import '../models/exam.dart' as exam_model;

/// Centralised constants and helpers for the Manual Flashcard Question Type
/// system.
///
/// The Drift `Flashcards` table stores the type as a TEXT column
/// (`questionType`) with one of the three string values below.  This class
/// keeps every part of the app referencing the same literals so there is no
/// guessing.
class QuestionTypeHelper {
  QuestionTypeHelper._();

  /// Stored database values (do NOT change — they are persisted).
  static const String identification = 'identification';
  static const String enumeration = 'enumeration';
  static const String multipleChoice = 'multiple_choice';

  static const List<String> all = [
    identification,
    enumeration,
    multipleChoice,
  ];

  /// Human-readable labels shown in selectors, chips, etc.
  static const Map<String, String> labels = {
    identification: 'Identification',
    enumeration: 'Enumeration',
    multipleChoice: 'Multiple Choice',
  };

  /// Short labels for compact chips.
  static const Map<String, String> shortLabels = {
    identification: 'ID',
    enumeration: 'Enum',
    multipleChoice: 'MCQ',
  };

  static String label(String type) => labels[type] ?? 'Identification';

  static String shortLabel(String type) => shortLabels[type] ?? 'ID';

  static bool isValid(String? type) => type != null && all.contains(type);

  /// Converts the stored string type to the [exam_model.QuestionType] enum
  /// used by the exam/study engines.
  static exam_model.QuestionType toExamQuestionType(String? type) {
    switch (type) {
      case multipleChoice:
        return exam_model.QuestionType.multipleChoice;
      case enumeration:
        return exam_model.QuestionType.enumeration;
      default:
        return exam_model.QuestionType.identification;
    }
  }

  /// Converts an [exam_model.QuestionType] back to the stored string.
  static String fromExamQuestionType(exam_model.QuestionType type) {
    switch (type) {
      case exam_model.QuestionType.multipleChoice:
        return multipleChoice;
      case exam_model.QuestionType.enumeration:
        return enumeration;
      case exam_model.QuestionType.identification:
      case exam_model.QuestionType.mixedFormat:
        return identification;
    }
  }

  // ── Enumeration items (stored as JSON array text) ──────────────────────

  /// Encodes a list of enumeration items into the JSON string stored in the
  /// `enumerationItems` column.
  static String encodeEnumerationItems(List<String> items) {
    return jsonEncode(items);
  }

  /// Decodes the `enumerationItems` column back to a list.  Returns an empty
  /// list when the column is null or malformed.
  static List<String> decodeEnumerationItems(String? json) {
    if (json == null || json.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      // fall through
    }
    return const [];
  }

  // ── Multiple-choice option helpers ─────────────────────────────────────

  static const List<String> optionLetters = ['A', 'B', 'C', 'D'];

  /// Returns the four options as a list `[A, B, C, D]`.  Null options become
  /// empty strings so callers always get a 4-element list.
  static List<String> optionsFromFlashcard(Flashcard flashcard) {
    return [
      flashcard.optionA ?? '',
      flashcard.optionB ?? '',
      flashcard.optionC ?? '',
      flashcard.optionD ?? '',
    ];
  }

  /// Returns the index (0-3) of the correct option, or -1 if not set.
  static int correctOptionIndex(Flashcard flashcard) {
    final letter = flashcard.correctOption?.toUpperCase();
    if (letter == null || letter.isEmpty) return -1;
    return optionLetters.indexOf(letter);
  }

  /// Maps a letter ('A'-'D') to its index (0-3).  Returns -1 for invalid.
  static int letterToIndex(String letter) {
    return optionLetters.indexOf(letter.toUpperCase());
  }

  /// Maps an index (0-3) to its letter ('A'-'D').  Returns '' for invalid.
  static String indexToLetter(int index) {
    if (index < 0 || index >= optionLetters.length) return '';
    return optionLetters[index];
  }

  // ── Backward compatibility with legacy encoded answers ─────────────────
  //
  // Older flashcards may have MCQ options encoded in the `answer` column
  // using the `|||` delimiter (see [FlashcardAnswerCodec]).  When the
  // dedicated option columns are null but the type is `multiple_choice`,
  // callers should fall back to decoding from the answer.

  /// Returns true when a flashcard has legacy-encoded MCQ options in its
  /// answer string and no dedicated option columns.
  static bool hasLegacyMcqEncoding(Flashcard flashcard) {
    return flashcard.questionType == multipleChoice &&
        flashcard.optionA == null &&
        flashcard.optionB == null &&
        flashcard.answer.contains('|||');
  }

  /// Returns the display answer for any flashcard regardless of type or
  /// legacy encoding.  For MCQ this is the correct option text; for
  /// enumeration this is the joined items; for identification the answer
  /// as stored (stripped of any legacy encoding).
  static String displayAnswer(Flashcard flashcard) {
    if (flashcard.questionType == multipleChoice) {
      // Prefer dedicated columns, fall back to legacy encoding.
      if (flashcard.optionA != null) {
        final idx = correctOptionIndex(flashcard);
        if (idx >= 0) {
          final opts = optionsFromFlashcard(flashcard);
          return opts[idx];
        }
      }
      // Legacy: strip the encoded options.
      final idx = flashcard.answer.indexOf('|||');
      return idx == -1
          ? flashcard.answer
          : flashcard.answer.substring(0, idx).trim();
    }
    if (flashcard.questionType == enumeration) {
      final items = decodeEnumerationItems(flashcard.enumerationItems);
      if (items.isNotEmpty) return items.join(', ');
      // Legacy: answer may hold comma-separated items.
      return flashcard.answer;
    }
    // identification (default)
    return flashcard.answer;
  }
}
