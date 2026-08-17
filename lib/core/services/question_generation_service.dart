import 'dart:convert';
import '../../core/models/prompt_template.dart';
import '../../core/models/exam.dart';
import '../../core/services/groq_service.dart';
import '../../core/services/document_extraction_service.dart';
import '../../core/services/text_normalization_service.dart';
import '../../core/services/content_capacity_service.dart';
import '../../core/services/question_validation_service.dart';

/// Maps a question type string back to its [PromptType].
PromptType? _promptTypeFromString(String? type) {
  final normalized = (type ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (normalized == 'multiplechoice' || normalized == 'multiple') {
    return PromptType.multipleChoice;
  }
  if (normalized == 'identification') {
    return PromptType.identification;
  }
  if (normalized == 'enumeration') {
    return PromptType.enumeration;
  }
  if (normalized == 'mixedformat' || normalized == 'mixed') {
    return PromptType.mixedFormat;
  }
  return null;
}

class GeneratedQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;
  final String? answer; // For identification/enumeration types
  final String? type;
  final String? difficulty;
  final String? source;
  final String? sourceText;
  final int? sourcePage;
  final String? sourceSection;

  GeneratedQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
    this.answer,
    this.type,
    this.difficulty,
    this.source,
    this.sourceText,
    this.sourcePage,
    this.sourceSection,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'answer': answer,
      'type': type,
      'difficulty': difficulty,
      'source': source,
      'sourceText': sourceText,
      'sourcePage': sourcePage,
      'sourceSection': sourceSection,
    };
  }

  factory GeneratedQuestion.fromJson(Map<String, dynamic> json) {
    return GeneratedQuestion(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List? ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
      explanation: json['explanation'] as String?,
      answer: json['answer'] as String?,
      type: json['type'] as String?,
      difficulty: json['difficulty'] as String?,
      source: json['source'] as String?,
      sourceText: json['sourceText'] as String?,
      sourcePage: json['sourcePage'] as int?,
      sourceSection: json['sourceSection'] as String?,
    );
  }

  ExamQuestion toExamQuestion(String id) {
    final questionType = QuestionValidationService.determineQuestionType(
      type: type,
      options: options,
      answer: answer,
      expected: _promptTypeFromString(type),
    );

    String? correctAnswerText;
    List<String>? correctAnswersList;

    if (questionType == QuestionType.identification) {
      final trimmed = answer?.trim();
      correctAnswerText = trimmed?.isNotEmpty == true
          ? IdentificationAnswerValidator.format(trimmed!)
          : null;
    } else if (questionType == QuestionType.enumeration) {
      final trimmed = answer?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        correctAnswersList = EnumerationFormatter.splitItems(trimmed);
      } else if (options.isNotEmpty) {
        correctAnswersList = options;
      } else {
        correctAnswersList = [];
      }
    }

    return ExamQuestion(
      id: id,
      question: question,
      type: questionType,
      options: questionType == QuestionType.multipleChoice ? options : const [],
      correctAnswerIndex: questionType == QuestionType.multipleChoice ? correctAnswerIndex : 0,
      correctAnswer: correctAnswerText,
      correctAnswers: correctAnswersList,
      explanation: explanation,
      flashcardId: null,
      source: source,
      sourceText: sourceText,
      sourcePage: sourcePage,
      sourceSection: sourceSection,
    );
  }
}

class QuestionGenerationService {
  final GroqService _groqService;

  QuestionGenerationService(this._groqService);

  /// Generate questions from source text
  Future<List<GeneratedQuestion>> generateQuestions({
    String? sourceText,
    required PromptType type,
    required Difficulty difficulty,
    required int questionCount,
    String? model,
    String? source,
    int? sourcePage,
    String? sourceSection,
  }) async {
    // Clean and reconstruct extracted text, then truncate if too long.
    final content = sourceText ?? '';
    final cleanedText = TextNormalizationService.cleanForPrompt(content);

    // Validate that the selected content can reasonably support the requested
    // number of unique questions before spending tokens on AI generation.
    final capacity = ContentCapacityService.estimate(cleanedText, type, questionCount);
    if (!capacity.isValid) {
      throw Exception(capacity.reason);
    }

    final truncatedText = DocumentExtractionService.truncateText(cleanedText);

    // Generate questions using Groq service
    final response = await _groqService.generateQuestionsWithBuiltInTemplate(
      content: truncatedText,
      type: type,
      questionCount: questionCount,
      difficulty: difficulty,
      model: model,
    );

    // Parse the response into structured questions
    final questions = _parseGeneratedQuestions(
      response,
      type,
      source: source,
      sourceText: sourceText,
      sourcePage: sourcePage,
      sourceSection: sourceSection,
    );
    final filteredQuestions = _filterPlaceholderDistractors(questions);
    
    // If too many questions were filtered out, log a warning but continue with what we have
    if (filteredQuestions.length < questions.length / 2) {
      // More than half were filtered out - this indicates poor AI generation
      // In production, you might want to retry generation here
    }
    
    return _deduplicateQuestions(filteredQuestions);
  }

  /// Remove near-duplicate questions using normalized text similarity.
  List<GeneratedQuestion> _deduplicateQuestions(List<GeneratedQuestion> questions) {
    final seen = <String>{};
    final unique = <GeneratedQuestion>[];
    for (final q in questions) {
      final key = _normalizeForDedup(q.question);
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(q);
      }
    }
    return unique;
  }

  static String _normalizeForDedup(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Parse AI-generated text into structured questions.
  ///
  /// First attempts a strict JSON response, then falls back to the
  /// plain-text template format, and finally returns a single fallback
  /// question so that valid content never produces an empty list.
  /// Remove Markdown and clean AI output so it renders safely in Text widgets
  /// while preserving paragraph breaks and line numbers.
  static String sanitizeText(String text) {
    // Normalize line endings first
    String cleaned = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    // Remove Markdown formatting without touching newlines
    cleaned = cleaned
        .replaceAll(RegExp(r'\*\*'), '') // bold
        .replaceAll(RegExp(r'__'), '') // underline
        .replaceAll(RegExp(r'#+\s*'), '') // headings
        .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '') // leading bullets
        .replaceAll(RegExp(r'```[\s\S]*?```'), '') // fenced code blocks
        .replaceAll(RegExp(r'`([^`]*)`'), r'$1'); // inline code markers

    // Remove excessive spaces/tabs, but keep newlines
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'[ \t]+'),
      (match) => ' ',
    );

    // Preserve double newlines (paragraphs), collapse more than two
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return cleaned.trim();
  }

  List<GeneratedQuestion> _sanitizeQuestions(List<GeneratedQuestion> questions) {
    return questions.map((q) {
      return GeneratedQuestion(
        question: sanitizeText(q.question),
        options: q.options.map(sanitizeText).toList(),
        correctAnswerIndex: q.correctAnswerIndex,
        explanation: q.explanation == null ? null : sanitizeText(q.explanation!),
        answer: q.answer == null ? null : sanitizeText(q.answer!),
        type: q.type,
        difficulty: q.difficulty,
        source: q.source,
        sourceText: q.sourceText,
        sourcePage: q.sourcePage,
        sourceSection: q.sourceSection,
      );
    }).toList();
  }

  /// Filter out questions with placeholder distractors
  List<GeneratedQuestion> _filterPlaceholderDistractors(List<GeneratedQuestion> questions) {
    final placeholderPatterns = [
      RegExp(r'incorrect option', caseSensitive: false),
      RegExp(r'wrong answer', caseSensitive: false),
      RegExp(r'placeholder', caseSensitive: false),
      RegExp(r'distractor \d+', caseSensitive: false),
      RegExp(r'^\s*\d+\.\s*$', caseSensitive: false), // Just numbers like "1."
      RegExp(r'^\s*[A-C]\)\s*$', caseSensitive: false), // Just labels like "A)"
      RegExp(
        r'^(none of the above|all of the above|not applicable|n/a|tbd|todo|unknown|other|none|all)$',
        caseSensitive: false,
      ),
      RegExp(r'^\s*[A-Da-d]\s*$'), // Single-letter options such as A, B, C, D
    ];

    return questions.where((question) {
      // Check each option (including the correct answer; single letters and
      // forbidden phrases are not acceptable for any option)
      for (int i = 0; i < question.options.length; i++) {
        final option = question.options[i].trim();

        // Check if option matches any placeholder pattern
        for (final pattern in placeholderPatterns) {
          if (pattern.hasMatch(option)) {
            return false; // Reject this question
          }
        }

        // Check if option is too short or empty
        if (option.length < 3) {
          return false; // Reject this question
        }
      }

      return true; // Keep this question
    }).toList();
  }

  List<GeneratedQuestion> _parseGeneratedQuestions(
    String response,
    PromptType type, {
    String? source,
    String? sourceText,
    int? sourcePage,
    String? sourceSection,
  }) {
    if (response.trim().isEmpty) {
      throw Exception('Empty response from AI');
    }

    List<GeneratedQuestion> questions;

    final jsonQuestions = _tryParseJsonQuestions(response);
    if (jsonQuestions.isNotEmpty) {
      questions = jsonQuestions;
    } else {
      try {
        switch (type) {
          case PromptType.multipleChoice:
            questions = _sanitizeQuestions(_parseMultipleChoiceQuestions(response));
            break;
          case PromptType.identification:
            questions = _sanitizeQuestions(_parseIdentificationQuestions(response));
            break;
          case PromptType.enumeration:
            questions = _sanitizeQuestions(_parseEnumerationQuestions(response));
            break;
          case PromptType.mixedFormat:
            questions = _sanitizeQuestions(_parseMixedFormatQuestions(response));
            break;
        }
      } catch (e) {
        // Fall back to a single question from the raw text.
        questions = _sanitizeQuestions(_fallbackSingleQuestion(response));
      }
    }

    return questions
        .map((q) => _applySourceAndType(
              q,
              type,
              source: source,
              sourceText: sourceText,
              sourcePage: sourcePage,
              sourceSection: sourceSection,
            ))
        .toList();
  }

  /// Returns the canonical string used to represent a [PromptType] in
  /// generated questions and flashcards.
  String _promptTypeToString(PromptType type) {
    switch (type) {
      case PromptType.multipleChoice:
        return 'multiple_choice';
      case PromptType.identification:
        return 'identification';
      case PromptType.enumeration:
        return 'enumeration';
      case PromptType.mixedFormat:
        return 'mixed_format';
    }
  }

  /// Applies the requested [PromptType] and source traceability fields to a
  /// parsed question, ensuring the final object reflects the user's request.
  GeneratedQuestion _applySourceAndType(
    GeneratedQuestion question,
    PromptType type, {
    String? source,
    String? sourceText,
    int? sourcePage,
    String? sourceSection,
  }) {
    final resolvedType = type == PromptType.mixedFormat
        ? question.type
        : _promptTypeToString(type);

    return GeneratedQuestion(
      question: question.question,
      options: question.options,
      correctAnswerIndex: question.correctAnswerIndex,
      explanation: question.explanation,
      answer: question.answer,
      type: resolvedType,
      difficulty: question.difficulty,
      source: source,
      sourceText: sourceText,
      sourcePage: sourcePage,
      sourceSection: sourceSection,
    );
  }

  /// Attempt to parse a JSON array or object containing questions.
  List<GeneratedQuestion> _tryParseJsonQuestions(String response) {
    final trimmed = response.trim();
    if (!trimmed.startsWith('[') && !trimmed.startsWith('{')) {
      return [];
    }

    try {
      final decoded = json.decode(trimmed);
      final rawList = decoded is List ? decoded : (decoded['questions'] as List? ?? []);
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((q) => _generatedQuestionFromJsonMap(q))
          .where((q) => q.question.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  GeneratedQuestion _generatedQuestionFromJsonMap(Map<String, dynamic> raw) {
    final options = List<String>.from(raw['options'] as List? ?? []);
    final rawAnswer = raw['answer'];
    int correctIndex;

    if (rawAnswer is int) {
      correctIndex = rawAnswer;
    } else if (rawAnswer is String && options.length == 4) {
      // Multiple choice answer letter A-D
      final letter = rawAnswer.trim().toUpperCase().replaceAll(RegExp(r'[).]+$'), '');
      correctIndex = 'ABCD'.indexOf(letter);
      if (correctIndex < 0) correctIndex = 0;
    } else {
      correctIndex = 0;
    }

    if (correctIndex < 0 || correctIndex >= options.length) {
      correctIndex = 0;
    }

    return GeneratedQuestion(
      question: (raw['question'] as String?) ?? '',
      options: options,
      correctAnswerIndex: correctIndex,
      explanation: raw['explanation'] as String?,
      answer: raw['answer']?.toString(),
      type: raw['type']?.toString(),
      difficulty: _normalizeDifficulty(raw['difficulty']?.toString()),
    );
  }

  String? _normalizeDifficulty(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[\[\]]'), '').trim().toLowerCase();
    if (cleaned.contains('easy')) return 'Easy';
    if (cleaned.contains('medium')) return 'Medium';
    if (cleaned.contains('hard')) return 'Hard';
    return raw.trim();
  }

  /// Last-resort fallback: return a single identification-style question
  /// using the beginning of the response so the user always gets something.
  List<GeneratedQuestion> _fallbackSingleQuestion(String response) {
    final text = response.trim();
    final firstLine = text.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => text);
    return [
      GeneratedQuestion(
        question: 'Based on the provided text, what is the key concept?\n\nText: $firstLine',
        options: [firstLine],
        correctAnswerIndex: 0,
        answer: firstLine,
      ),
    ];
  }

  /// Parses a mixed-format response by first trying strict JSON, then
  /// classifying each question block as multiple-choice, identification,
  /// or enumeration based on its structure.
  List<GeneratedQuestion> _parseMixedFormatQuestions(String response) {
    final jsonQuestions = _tryParseJsonQuestions(response);
    if (jsonQuestions.isNotEmpty) return jsonQuestions;

    final prepared = response
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();

    // Split on explicit "Question:" markers.
    var blocks = prepared.split(RegExp(r'(?=^Question:)', multiLine: true));
    if (blocks.length <= 1) {
      // Try legacy markers such as Q1. or 1. and normalize to "Question:".
      blocks = prepared.split(RegExp(r'(?=^Q\d+[:.]|^\d+\.)', multiLine: true));
      blocks = blocks.map((b) => b.replaceFirstMapped(
        RegExp(r'^(?:Q\d+|\d+)[:.]?\s*'),
        (match) => 'Question: ',
      )).toList();
    }

    final questions = <GeneratedQuestion>[];
    for (final block in blocks) {
      if (block.trim().isEmpty) continue;

      // Try multiple choice first (requires exactly four A-D options).
      final mc = parseSingleMultipleChoice(block, questionType: 'multiple_choice');
      if (mc != null) {
        questions.add(mc);
        continue;
      }

      // Try enumeration (list-style answer with multiple items).
      final enumQ = _parseSingleEnumeration(block);
      if (enumQ != null) {
        questions.add(enumQ);
        continue;
      }

      // Finally try identification.
      final idQ = _parseSingleIdentification(block);
      if (idQ != null) {
        questions.add(idQ);
      }
    }

    return questions.isNotEmpty ? questions : _fallbackSingleQuestion(response);
  }

  /// Parse multiple choice questions from the template format:
  ///
  /// Question: [text]
  /// A) [option]
  /// B) [option]
  /// C) [option]
  /// D) [option]
  /// Correct Answer: [A-D]
  /// Explanation: [why correct]
  List<GeneratedQuestion> _parseMultipleChoiceQuestions(String response) {
    final questions = <GeneratedQuestion>[];

    // Split on explicit "Question:" markers.
    final blocks = response.split(RegExp(r'(?=^Question:)', multiLine: true));

    for (final block in blocks) {
      if (block.trim().isEmpty) continue;

      try {
        final question = parseSingleMultipleChoice(block);
        if (question != null) {
          questions.add(question);
        }
      } catch (e) {
        continue;
      }
    }

    if (questions.isEmpty) {
      // Fallback to generic question marker (Q1, 1., etc.)
      final legacyBlocks = response.split(RegExp(r'(?=^Q\d+[:.]|^\d+\.)', multiLine: true));
      for (final block in legacyBlocks) {
        if (block.trim().isEmpty) continue;
        try {
          final question = _parseLegacyMultipleChoice(block);
          if (question != null) questions.add(question);
        } catch (e) {
          continue;
        }
      }
    }

    return questions;
  }

  /// Parses a single multiple choice block into a [GeneratedQuestion].
  ///
  /// Only accepts option labels in the form `A.`, `A)`, `a.`, `a)`.
  /// Lines beginning with `Correct Answer`, `Answer`, `Explanation`, `Reason`,
  /// or `Rationale` are never treated as options.
  static GeneratedQuestion? parseSingleMultipleChoice(String block, {String? questionType}) {
    final normalized = block
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    // Extract question text after "Question:"
    final questionMatch = RegExp(
      r'^Question:\s*(.+?)(?=\n[A-Za-z][.)]|\nCorrect Answer:|\nAnswer:|\nExplanation:|\nReason:|\nRationale:|\n\n|\nQuestion:|$)',
      dotAll: true,
      multiLine: true,
      caseSensitive: false,
    ).firstMatch(normalized);
    if (questionMatch == null) return null;

    final questionText = sanitizeText(questionMatch.group(1)?.trim() ?? '');
    if (questionText.isEmpty) return null;

    // Extract only A-D options with strict "." or ")" delimiters.
    final optionMatches = RegExp(
      r'^([A-Za-z])[.)]\s*(.+?)(?=\n[A-Za-z][.)]|\nCorrect Answer:|\nAnswer:|\nExplanation:|\nReason:|\nRationale:|\n\n|\nQuestion:|$)',
      dotAll: true,
      multiLine: true,
      caseSensitive: false,
    ).allMatches(normalized);

    final optionsByLetter = <String, String>{};
    final seenKeys = <String>{};
    for (final match in optionMatches) {
      final letter = (match.group(1) ?? '').toUpperCase();
      if (!'ABCD'.contains(letter)) continue;

      final rawText = match.group(2)?.trim() ?? '';
      final text = _stripOptionPrefix(sanitizeText(rawText));
      if (text.isEmpty) continue;

      final key = _normalizeForDedup(text);
      if (seenKeys.contains(key)) continue;
      seenKeys.add(key);

      if (!optionsByLetter.containsKey(letter)) {
        optionsByLetter[letter] = text;
      }
    }

    if (optionsByLetter.length != 4) return null;

    final options = ['A', 'B', 'C', 'D'].map((l) => optionsByLetter[l]!).toList();

    // Extract correct answer (accepts "A", "A)", "A.")
    final correctLetter = _extractMultipleChoiceAnswer(normalized);
    if (correctLetter == null) return null;

    final correctIndex = 'ABCD'.indexOf(correctLetter);
    if (correctIndex < 0 || correctIndex >= options.length) return null;

    final explanation = _extractMultipleChoiceExplanation(normalized);

    return GeneratedQuestion(
      question: questionText,
      options: options,
      correctAnswerIndex: correctIndex,
      explanation: explanation,
      answer: correctLetter,
      type: questionType ?? 'multiple_choice',
    );
  }

  /// Parses the correct answer letter from a multiple choice block.
  static String? _extractMultipleChoiceAnswer(String block) {
    final correctMatch = RegExp(
      r'^Correct Answer[:\s]*([A-Da-d])',
      multiLine: true,
      caseSensitive: false,
    ).firstMatch(block);
    if (correctMatch != null) {
      return correctMatch.group(1)?.toUpperCase();
    }

    final answerMatch = RegExp(
      r'^Answer[:\s]*([A-Da-d])',
      multiLine: true,
      caseSensitive: false,
    ).firstMatch(block);
    return answerMatch?.group(1)?.toUpperCase();
  }

  /// Parses the explanation from a multiple choice block.
  static String? _extractMultipleChoiceExplanation(String block) {
    final match = RegExp(
      r'^Explanation[:\s]*(.+?)(?=\n\n|\nQuestion:|$)',
      dotAll: true,
      multiLine: true,
      caseSensitive: false,
    ).firstMatch(block);
    return match?.group(1)?.trim();
  }

  /// Strips any remaining leading option label from the option text.
  ///
  /// Requires a single A-D letter followed by "." or ")" so it does not
  /// accidentally remove the first letter of an option like "Central".
  static String _stripOptionPrefix(String text) {
    return text
        .replaceFirst(RegExp(r'^\s*[A-Da-d][.)]\s+'), '')
        .trim();
  }

  /// Legacy parser for responses that use Q1 / 1. markers.
  GeneratedQuestion? _parseLegacyMultipleChoice(String block) {
    final normalized = block
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    if (normalized.isEmpty) return null;

    // Convert leading Q1. or 1. markers into the standard "Question:" form.
    final prepared = normalized.replaceFirstMapped(
      RegExp(r'^(?:Q\d+|\d+)[:.]?\s*'),
      (match) => 'Question: ',
    );
    return parseSingleMultipleChoice(prepared);
  }

  /// Parse identification questions.
  List<GeneratedQuestion> _parseIdentificationQuestions(String response) {
    final questions = <GeneratedQuestion>[];
    final blocks = response.split(RegExp(r'(?=^Question:)', multiLine: true));

    for (final block in blocks) {
      if (block.trim().isEmpty) continue;
      try {
        final question = _parseSingleIdentification(block);
        if (question != null) questions.add(question);
      } catch (e) {
        continue;
      }
    }

    if (questions.isEmpty) {
      final legacyBlocks = response.split(RegExp(r'(?=^Q\d+[:.]|^\d+\.)', multiLine: true));
      for (final block in legacyBlocks) {
        if (block.trim().isEmpty) continue;
        try {
          final question = _parseSingleIdentification(block);
          if (question != null) questions.add(question);
        } catch (e) {
          continue;
        }
      }
    }

    return questions;
  }

  GeneratedQuestion? _parseSingleIdentification(String block) {
    final questionMatch = RegExp(
      r'^Question:\s*(.+?)(?=\nAnswer:|$)',
      dotAll: true,
      multiLine: true,
    ).firstMatch(block);
    if (questionMatch == null) return null;

    final questionText = questionMatch.group(1)?.trim() ?? '';
    if (questionText.isEmpty) return null;

    final answerMatch = RegExp(
      r'Answer[:\s]*(.+?)(?=\n\n|\nQuestion:|$)',
      dotAll: true,
      multiLine: true,
    ).firstMatch(block);
    var answer = answerMatch?.group(1)?.trim();

    if (answer == null || answer.isEmpty) return null;
    answer = IdentificationAnswerValidator.format(answer);
    if (answer.isEmpty) return null;

    return GeneratedQuestion(
      question: questionText,
      options: const [],
      correctAnswerIndex: -1,
      answer: answer,
      type: 'identification',
    );
  }

  /// Parse enumeration questions.
  List<GeneratedQuestion> _parseEnumerationQuestions(String response) {
    final questions = <GeneratedQuestion>[];
    final blocks = response.split(RegExp(r'(?=^Question:)', multiLine: true));

    for (final block in blocks) {
      if (block.trim().isEmpty) continue;
      try {
        final question = _parseSingleEnumeration(block);
        if (question != null) questions.add(question);
      } catch (e) {
        continue;
      }
    }

    if (questions.isEmpty) {
      final legacyBlocks = response.split(RegExp(r'(?=^Q\d+[:.]|^\d+\.)', multiLine: true));
      for (final block in legacyBlocks) {
        if (block.trim().isEmpty) continue;
        try {
          final question = _parseSingleEnumeration(block);
          if (question != null) questions.add(question);
        } catch (e) {
          continue;
        }
      }
    }

    return questions;
  }

  GeneratedQuestion? _parseSingleEnumeration(String block) {
    final questionMatch = RegExp(
      r'^Question:\s*(.+?)(?=\nAnswer:|$)',
      dotAll: true,
      multiLine: true,
    ).firstMatch(block);
    if (questionMatch == null) return null;

    final questionText = questionMatch.group(1)?.trim() ?? '';
    if (questionText.isEmpty) return null;

    // Items may be numbered (1.) or bulleted (- / •).
    final items = <String>[];
    final itemRegex = RegExp(r'(?:^\d+[).-]?\s*|^[-•]\s*)(.+?)(?=\n(?:\d+[).-]?\s*|[-•]\s*)|\n\n|\nQuestion:|$)', multiLine: true);
    for (final match in itemRegex.allMatches(block)) {
      items.add(match.group(1)?.trim() ?? '');
    }

    if (items.isEmpty) return null;

    final answer = EnumerationFormatter.format(items.join(', '));

    return GeneratedQuestion(
      question: questionText,
      options: const [],
      correctAnswerIndex: -1,
      answer: answer,
      type: 'enumeration',
    );
  }



  /// Convert generated questions to exam questions
  List<ExamQuestion> toExamQuestions(List<GeneratedQuestion> generatedQuestions) {
    return generatedQuestions
        .asMap()
        .entries
        .map((entry) => entry.value.toExamQuestion('q_${entry.key}'))
        .toList();
  }

  /// Validate generated questions
  List<String> validateQuestions(List<GeneratedQuestion> questions) {
    final issues = <String>[];

    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final questionType = QuestionValidationService.determineQuestionType(
        type: question.type,
        options: question.options,
        answer: question.answer,
      );

      issues.addAll(QuestionValidationService.validateQuestion(
        type: questionType,
        question: question.question,
        options: question.options,
        correctAnswerIndex: question.correctAnswerIndex,
        answer: question.answer,
        questionIndex: i,
      ));

      if (questionType == QuestionType.multipleChoice) {
        issues.addAll(_validateDistractorQuality(question, i));
      }
    }

    return issues;
  }

  /// Validate distractor quality for multiple choice questions
  List<String> _validateDistractorQuality(GeneratedQuestion question, int questionIndex) {
    final issues = <String>[];
    
    if (question.options.length < 4) {
      issues.add('Question ${questionIndex + 1}: Multiple choice must have exactly 4 options');
      return issues;
    }

    final correctAnswer = question.options[question.correctAnswerIndex];
    final distractors = <String>[];
    for (int i = 0; i < question.options.length; i++) {
      if (i != question.correctAnswerIndex) {
        distractors.add(question.options[i]);
      }
    }

    // Check for placeholder text
    final placeholderPatterns = [
      RegExp(r'incorrect option', caseSensitive: false),
      RegExp(r'wrong answer', caseSensitive: false),
      RegExp(r'placeholder', caseSensitive: false),
      RegExp(r'distractor \d+', caseSensitive: false),
    ];

    for (final distractor in distractors) {
      for (final pattern in placeholderPatterns) {
        if (pattern.hasMatch(distractor)) {
          issues.add('Question ${questionIndex + 1}: Contains placeholder distractor: "$distractor"');
        }
      }
    }

    // Check for "none of the above" or "all of the above"
    final invalidPhrases = [
      RegExp(r'none of the above', caseSensitive: false),
      RegExp(r'all of the above', caseSensitive: false),
      RegExp(r'both a and b', caseSensitive: false),
      RegExp(r'both a and c', caseSensitive: false),
      RegExp(r'both b and c', caseSensitive: false),
    ];

    for (final distractor in distractors) {
      for (final pattern in invalidPhrases) {
        if (pattern.hasMatch(distractor)) {
          issues.add('Question ${questionIndex + 1}: Contains invalid phrase in distractor: "$distractor"');
        }
      }
    }

    // Check for duplicate distractors
    final normalizedDistractors = distractors.map((d) => d.toLowerCase().trim()).toSet();
    if (normalizedDistractors.length < distractors.length) {
      issues.add('Question ${questionIndex + 1}: Contains duplicate distractors');
    }

    // Check if distractors are too similar to correct answer
    for (final distractor in distractors) {
      if (distractor.toLowerCase().trim() == correctAnswer.toLowerCase().trim()) {
        issues.add('Question ${questionIndex + 1}: Distractor is identical to correct answer');
      }
    }

    return issues;
  }
}