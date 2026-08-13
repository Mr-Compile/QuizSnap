import 'dart:convert';
import '../../core/models/prompt_template.dart';
import '../../core/models/exam.dart';
import '../../core/services/groq_service.dart';
import '../../core/services/document_extraction_service.dart';
import '../../core/services/text_normalization_service.dart';
import '../../core/services/question_validation_service.dart';

class GeneratedQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;
  final String? answer; // For identification/enumeration types
  final String? type;
  final String? difficulty;

  GeneratedQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
    this.answer,
    this.type,
    this.difficulty,
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
    );
  }

  ExamQuestion toExamQuestion(String id) {
    // Determine the question type based on the generated structure
    QuestionType questionType;
    if (type == 'identification' || (options.length <= 1 && answer != null)) {
      questionType = QuestionType.identification;
    } else if (type == 'enumeration' || (options.length > 1 && answer != null)) {
      questionType = QuestionType.enumeration;
    } else if (type == 'mixed' || type == 'mixed_format') {
      questionType = QuestionType.mixedFormat;
    } else {
      questionType = QuestionType.multipleChoice;
    }

    // Set type-specific fields
    String? correctAnswerText;
    List<String>? correctAnswersList;

    if (questionType == QuestionType.identification) {
      correctAnswerText = answer;
    } else if (questionType == QuestionType.enumeration) {
      if (options.length > 1) {
        correctAnswersList = options;
      } else if (answer != null) {
        correctAnswersList = [answer!];
      } else {
        correctAnswersList = [];
      }
    }

    return ExamQuestion(
      id: id,
      question: question,
      type: questionType,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      correctAnswer: correctAnswerText,
      correctAnswers: correctAnswersList,
      explanation: explanation,
      flashcardId: null,
    );
  }
}

class QuestionGenerationService {
  final GroqService _groqService;

  QuestionGenerationService(this._groqService);

  /// Generate questions from source text
  Future<List<GeneratedQuestion>> generateQuestions({
    required String sourceText,
    required PromptType type,
    required Difficulty difficulty,
    required int questionCount,
    String? model,
  }) async {
    // Clean and reconstruct extracted text, then truncate if too long.
    final cleanedText = TextNormalizationService.cleanForPrompt(sourceText);
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
    final questions = _parseGeneratedQuestions(response, type);
    return _deduplicateQuestions(questions);
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
      );
    }).toList();
  }

  List<GeneratedQuestion> _parseGeneratedQuestions(String response, PromptType type) {
    if (response.trim().isEmpty) {
      throw Exception('Empty response from AI');
    }

    final jsonQuestions = _tryParseJsonQuestions(response);
    if (jsonQuestions.isNotEmpty) return jsonQuestions;

    try {
      switch (type) {
        case PromptType.multipleChoice:
          return _sanitizeQuestions(_parseMultipleChoiceQuestions(response));
        case PromptType.identification:
          return _sanitizeQuestions(_parseIdentificationQuestions(response));
        case PromptType.enumeration:
          return _sanitizeQuestions(_parseEnumerationQuestions(response));
        case PromptType.examSimulation:
          return _sanitizeQuestions(_parseExamSimulationQuestions(response));
        case PromptType.explanation:
          return _sanitizeQuestions(_parseExplanationQuestions(response));
        case PromptType.studyDeck:
          return _sanitizeQuestions(_parseStudyDeckQuestions(response));
        case PromptType.mixed:
          return _sanitizeQuestions(_tryParseJsonQuestions(response));
      }
    } catch (e) {
      // Fall back to a single question from the raw text.
      return _sanitizeQuestions(_fallbackSingleQuestion(response));
    }
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
  static GeneratedQuestion? parseSingleMultipleChoice(String block) {
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
    final answer = answerMatch?.group(1)?.trim();

    if (answer == null || answer.isEmpty) return null;

    return GeneratedQuestion(
      question: questionText,
      options: [answer],
      correctAnswerIndex: 0,
      answer: answer,
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

    final answer = items.join(', ');

    return GeneratedQuestion(
      question: questionText,
      options: items,
      correctAnswerIndex: 0,
      answer: answer,
    );
  }

  /// Parse exam simulation questions (mixed types)
  List<GeneratedQuestion> _parseExamSimulationQuestions(String response) {
    // Default to multiple choice parsing for exam simulation
    return _parseMultipleChoiceQuestions(response);
  }

  /// Parse explanation questions
  List<GeneratedQuestion> _parseExplanationQuestions(String response) {
    // Similar to multiple choice but with required explanations
    final questions = _parseMultipleChoiceQuestions(response);
    
    // Ensure all questions have explanations
    return questions.map((q) {
      if (q.explanation == null || q.explanation!.isEmpty) {
        return GeneratedQuestion(
          question: q.question,
          options: q.options,
          correctAnswerIndex: q.correctAnswerIndex,
          explanation: 'This is the correct answer based on the content.',
        );
      }
      return q;
    }).toList();
  }

  /// Parse study deck questions (mixed types with two-section format)
  List<GeneratedQuestion> _parseStudyDeckQuestions(String response) {
    final questions = <GeneratedQuestion>[];
    
    // Split into sections
    final sections = response.split(RegExp(r'SECTION 2:|ANSWER KEY', caseSensitive: false));
    if (sections.length < 2) {
      // Fallback to multiple choice parsing if sections not found
      return _parseMultipleChoiceQuestions(response);
    }
    
    final questionsSection = sections[0];
    final answersSection = sections[1];
    
    // Parse questions from section 1
    final questionBlocks = questionsSection.split(RegExp(r'Item \d+', caseSensitive: false));
    
    for (final block in questionBlocks) {
      if (block.trim().isEmpty) continue;
      
      try {
        final question = _parseStudyDeckItem(block, answersSection);
        if (question != null) {
          questions.add(question);
        }
      } catch (e) {
        continue;
      }
    }
    
    return questions;
  }

  GeneratedQuestion? _parseStudyDeckItem(String questionBlock, String answersSection) {
    // Extract question type and difficulty
    final typeMatch = RegExp(r'\| ([^\|]+) \| ([^\|]+)').firstMatch(questionBlock);
    // ignore: unused_local_variable
    final questionType = typeMatch?.group(1)?.trim() ?? 'Multiple Choice';
    // ignore: unused_local_variable
    final difficulty = typeMatch?.group(2)?.trim() ?? 'Medium';
    
    // Extract question prompt
    final promptMatch = RegExp(r'Question Prompt: (.+?)(?=Options:|$)', dotAll: true).firstMatch(questionBlock);
    final questionText = promptMatch?.group(1)?.trim() ?? '';
    
    if (questionText.isEmpty) return null;
    
    // Extract options if present
    final options = <String>[];
    final optionRegex = RegExp(r'[A-D]\) (.+?)(?=\n[A-D]|$)', multiLine: true);
    
    for (final match in optionRegex.allMatches(questionBlock)) {
      options.add(match.group(1)?.trim() ?? '');
    }
    
    // Find corresponding answer from section 2
    final itemNumberMatch = RegExp(r'Item (\d+)').firstMatch(questionBlock);
    // ignore: unused_local_variable
    final itemNumber = itemNumberMatch?.group(1) ?? '';
    
    final answerMatch = RegExp(
      'Item $itemNumber Answer: (.+?)(?=Explanation:|\\nItem |${String.fromCharCode(36)})',
      dotAll: true,
    ).firstMatch(answersSection);
    final answer = answerMatch?.group(1)?.trim();

    final explanationMatch = RegExp(
      'Item $itemNumber Explanation: (.+?)(?=Item \\d+|${String.fromCharCode(36)})',
      dotAll: true,
    ).firstMatch(answersSection);
    final explanation = explanationMatch?.group(1)?.trim();
    
    // Determine correct answer index based on options
    int correctAnswerIndex = 0;
    if (options.isNotEmpty && answer != null) {
      final answerIndex = options.indexWhere((opt) => opt.contains(answer) || answer.contains(opt));
      if (answerIndex >= 0) {
        correctAnswerIndex = answerIndex;
      }
    }
    
    return GeneratedQuestion(
      question: questionText,
      options: options.isNotEmpty ? options : [answer ?? ''],
      correctAnswerIndex: correctAnswerIndex,
      explanation: explanation,
      answer: answer,
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

      if (question.question.trim().isEmpty) {
        issues.add('Question ${i + 1}: Empty question text');
      }

      // Type-aware validation
      final questionType = _determineQuestionType(question);
      
      switch (questionType) {
        case QuestionType.multipleChoice:
          issues.addAll(_validateMultipleChoiceQuestion(question, i));
          break;
        case QuestionType.identification:
          issues.addAll(_validateIdentificationQuestion(question, i));
          break;
        case QuestionType.enumeration:
          issues.addAll(_validateEnumerationQuestion(question, i));
          break;
        case QuestionType.mixedFormat:
          // For mixed format, validate based on structure
          if (question.options.length >= 4) {
            issues.addAll(_validateMultipleChoiceQuestion(question, i));
          } else {
            issues.addAll(_validateIdentificationQuestion(question, i));
          }
          break;
      }
    }

    return issues;
  }

  QuestionType _determineQuestionType(GeneratedQuestion question) {
    if (question.type == 'identification' || (question.options.length <= 1 && question.answer != null)) {
      return QuestionType.identification;
    } else if (question.type == 'enumeration' || (question.options.length > 1 && question.answer != null)) {
      return QuestionType.enumeration;
    } else if (question.type == 'mixed' || question.type == 'mixed_format') {
      return QuestionType.mixedFormat;
    } else {
      return QuestionType.multipleChoice;
    }
  }

  List<String> _validateMultipleChoiceQuestion(GeneratedQuestion question, int questionIndex) {
    final issues = <String>[];

    if (question.options.length != 4) {
      issues.add('Question ${questionIndex + 1}: Multiple choice must have exactly 4 options (found ${question.options.length})');
    }

    if (question.correctAnswerIndex < 0 || question.correctAnswerIndex >= question.options.length) {
      issues.add('Question ${questionIndex + 1}: Invalid correct answer index');
    }

    issues.addAll(MultipleChoiceQuestionValidator.validate(
      options: question.options,
      correctAnswerIndex: question.correctAnswerIndex,
      questionIndex: questionIndex,
      answer: question.answer,
    ));

    // Validate distractor quality
    issues.addAll(_validateDistractorQuality(question, questionIndex));

    return issues;
  }

  List<String> _validateIdentificationQuestion(GeneratedQuestion question, int questionIndex) {
    final issues = <String>[];

    if (question.answer == null || question.answer!.trim().isEmpty) {
      issues.add('Question ${questionIndex + 1}: Identification questions must have a correct answer');
    }

    // Identification questions should not have options (or have empty options)
    if (question.options.length > 1) {
      issues.add('Question ${questionIndex + 1}: Identification questions should not have multiple options');
    }

    issues.addAll(IdentificationAnswerValidator.validate(question.answer ?? '', questionIndex));

    return issues;
  }

  List<String> _validateEnumerationQuestion(GeneratedQuestion question, int questionIndex) {
    final issues = <String>[];

    if (question.answer == null || question.answer!.trim().isEmpty) {
      issues.add('Question ${questionIndex + 1}: Enumeration questions must have correct answers');
    }

    // Enumeration questions can have options as the answer list
    if (question.options.isEmpty && (question.answer == null || question.answer!.isEmpty)) {
      issues.add('Question ${questionIndex + 1}: Enumeration questions must have answer items');
    }

    issues.addAll(EnumerationFormatter.validate(question.answer ?? '', questionIndex));

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