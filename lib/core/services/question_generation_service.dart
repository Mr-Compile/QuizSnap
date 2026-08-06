import '../../core/models/prompt_template.dart';
import '../../core/models/exam.dart';
import '../../core/services/groq_service.dart';
import '../../core/services/document_extraction_service.dart';

class GeneratedQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;
  final String? answer; // For identification/enumeration types

  GeneratedQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
    this.answer,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'answer': answer,
    };
  }

  factory GeneratedQuestion.fromJson(Map<String, dynamic> json) {
    return GeneratedQuestion(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      explanation: json['explanation'] as String?,
      answer: json['answer'] as String?,
    );
  }

  ExamQuestion toExamQuestion(String id) {
    return ExamQuestion(
      id: id,
      question: question,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      explanation: explanation,
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
  }) async {
    // Truncate text if too long
    final truncatedText = DocumentExtractionService.truncateText(sourceText);
    
    // Generate questions using Groq service
    final response = await _groqService.generateQuestionsWithBuiltInTemplate(
      content: truncatedText,
      type: type,
      questionCount: questionCount,
      difficulty: difficulty,
    );

    // Parse the response into structured questions
    return _parseGeneratedQuestions(response, type);
  }

  /// Parse AI-generated text into structured questions
  List<GeneratedQuestion> _parseGeneratedQuestions(String response, PromptType type) {
    final questions = <GeneratedQuestion>[];

    try {
      switch (type) {
        case PromptType.multipleChoice:
          return _parseMultipleChoiceQuestions(response);
        case PromptType.identification:
          return _parseIdentificationQuestions(response);
        case PromptType.enumeration:
          return _parseEnumerationQuestions(response);
        case PromptType.examSimulation:
          return _parseExamSimulationQuestions(response);
        case PromptType.explanation:
          return _parseExplanationQuestions(response);
      }
    } catch (e) {
      throw Exception('Failed to parse generated questions: $e');
    }
  }

  /// Parse multiple choice questions
  List<GeneratedQuestion> _parseMultipleChoiceQuestions(String response) {
    final questions = <GeneratedQuestion>[];
    
    // Split by question markers (Q1, Q2, 1., etc.)
    final questionBlocks = response.split(RegExp(r'(?=Q\d+|^\d+\.)', multiLine: true));
    
    for (final block in questionBlocks) {
      if (block.trim().isEmpty) continue;
      
      try {
        final question = _parseSingleMultipleChoice(block);
        if (question != null) {
          questions.add(question);
        }
      } catch (e) {
        // Skip malformed questions
        continue;
      }
    }
    
    return questions;
  }

  GeneratedQuestion? _parseSingleMultipleChoice(String block) {
    // Extract question text
    final questionMatch = RegExp(r'Q\d+[:.]?\s*(.+?)(?=\n|$)').firstMatch(block);
    if (questionMatch == null) return null;
    
    final questionText = questionMatch.group(1)?.trim() ?? '';
    
    // Extract options (A, B, C, D)
    final options = <String>[];
    final optionRegex = RegExp(r'([A-D])[:.]?\s*(.+?)(?=\n[A-D]|$)', multiLine: true);
    
    for (final match in optionRegex.allMatches(block)) {
      options.add(match.group(2)?.trim() ?? '');
    }
    
    if (options.length < 2) return null;
    
    // Extract correct answer
    final answerMatch = RegExp(r'Answer[:\s]*([A-D])', caseInsensitive: true).firstMatch(block);
    if (answerMatch == null) return null;
    
    final correctLetter = answerMatch.group(1)?.toUpperCase();
    final correctIndex = 'ABCD'.indexOf(correctLetter ?? '');
    
    if (correctIndex < 0 || correctIndex >= options.length) return null;
    
    // Extract explanation if present
    final explanationMatch = RegExp(r'Explanation[:\s]*(.+?)(?=\n\n|$)', dotAll: true).firstMatch(block);
    final explanation = explanationMatch?.group(1)?.trim();
    
    return GeneratedQuestion(
      question: questionText,
      options: options,
      correctAnswerIndex: correctIndex,
      explanation: explanation,
    );
  }

  /// Parse identification questions
  List<GeneratedQuestion> _parseIdentificationQuestions(String response) {
    final questions = <GeneratedQuestion>[];
    
    final questionBlocks = response.split(RegExp(r'(?=Q\d+|^\d+\.)', multiLine: true));
    
    for (final block in questionBlocks) {
      if (block.trim().isEmpty) continue;
      
      try {
        final question = _parseSingleIdentification(block);
        if (question != null) {
          questions.add(question);
        }
      } catch (e) {
        continue;
      }
    }
    
    return questions;
  }

  GeneratedQuestion? _parseSingleIdentification(String block) {
    final questionMatch = RegExp(r'Q\d+[:.]?\s*(.+?)(?=\nAnswer:|$)', dotAll: true).firstMatch(block);
    if (questionMatch == null) return null;
    
    final questionText = questionMatch.group(1)?.trim() ?? '';
    
    final answerMatch = RegExp(r'Answer[:\s]*(.+?)(?=\n\n|$)', dotAll: true).firstMatch(block);
    final answer = answerMatch?.group(1)?.trim();
    
    if (answer == null || answer.isEmpty) return null;
    
    return GeneratedQuestion(
      question: questionText,
      options: [answer], // Single option for identification
      correctAnswerIndex: 0,
      answer: answer,
    );
  }

  /// Parse enumeration questions
  List<GeneratedQuestion> _parseEnumerationQuestions(String response) {
    final questions = <GeneratedQuestion>[];
    
    final questionBlocks = response.split(RegExp(r'(?=Q\d+|^\d+\.)', multiLine: true));
    
    for (final block in questionBlocks) {
      if (block.trim().isEmpty) continue;
      
      try {
        final question = _parseSingleEnumeration(block);
        if (question != null) {
          questions.add(question);
        }
      } catch (e) {
        continue;
      }
    }
    
    return questions;
  }

  GeneratedQuestion? _parseSingleEnumeration(String block) {
    final questionMatch = RegExp(r'Q\d+[:.]?\s*(.+?)(?=\nAnswer:|$)', dotAll: true).firstMatch(block);
    if (questionMatch == null) return null;
    
    final questionText = questionMatch.group(1)?.trim() ?? '';
    
    // Extract enumerated items
    final items = <String>[];
    final itemRegex = RegExp(r'[-•]\s*(.+?)(?=\n[-•]|$)', multiLine: true);
    
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

  /// Convert generated questions to exam questions
  List<ExamQuestion> toExamQuestions(List<GeneratedQuestion> generatedQuestions) {
    return generatedQuestions
        .asMap()
        .map((index, question) => question.toExamQuestion('q_$index'))
        .values
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
      
      if (question.options.isEmpty) {
        issues.add('Question ${i + 1}: No options provided');
      }
      
      if (question.correctAnswerIndex < 0 || question.correctAnswerIndex >= question.options.length) {
        issues.add('Question ${i + 1}: Invalid correct answer index');
      }
    }
    
    return issues;
  }
}