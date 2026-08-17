import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:groq/groq.dart';
import '../models/prompt_template.dart';
import '../models/groq_models.dart';
import '../repositories/prompt_template_repository.dart';
import '../models/exam.dart';
import 'secure_storage_service.dart';

class GroqService {
  String? _apiKey;
  Groq? _client;
  String? _currentModel;
  final PromptTemplateRepository _templateRepository = PromptTemplateRepository();
  final SecureStorageService _secureStorage;

  bool get isInitialized => _apiKey != null && _client != null;
  String? get currentModel => _currentModel;

  GroqService() : _secureStorage = SecureStorageService();

  Future<void> initialize(String apiKey, {String? model}) async {
    _apiKey = apiKey;
    _currentModel = model ?? GroqModels.getDefaultModel();

    _client = Groq(
      apiKey: apiKey,
      configuration: _buildConfiguration(_currentModel!),
    );

    await _templateRepository.initialize();
    // Store the API key securely
    await _secureStorage.storeGroqApiKey(apiKey);
  }

  Future<void> initializeFromSecureStorage({String? model}) async {
    final apiKey = await _secureStorage.getGroqApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      _apiKey = apiKey;
      _currentModel = model ?? GroqModels.getDefaultModel();

      _client = Groq(
        apiKey: apiKey,
        configuration: _buildConfiguration(_currentModel!),
      );

      await _templateRepository.initialize();
    }
  }

  Configuration _buildConfiguration(String model) {
    // Note: this Groq SDK sends `topP` but the Groq API expects `top_p`.
    // Passing `topP` causes "Unknown parameter topP" errors, so it is omitted.
    return Configuration(
      model: model,
      temperature: 0.25,
      maxCompletionTokens: 4096,
      seed: 42,
    );
  }

  String _buildSystemMessage(PromptTemplate template) {
    return '''You are an expert educator writing study content for a Flutter flashcard app.

CRITICAL OUTPUT RULES:
1. NO MARKDOWN. Do not use **, ##, __, leading bullets (- or *), fenced code blocks, or any Markdown.
2. Write like a real human instructor. Do not write "Here is your exam", "The following questions are generated", "As an AI", or similar robotic openings.
3. Avoid buzzwords: delve, leverage, tapestry, crucial, fostering.
4. Every item must be ATOMIC: one concept per item, short answer (1-3 sentences), concise lists for enumeration.
5. Each item must be labeled with a difficulty: [Easy], [Medium], or [Hard].
6. Use plain text only. Numbers and letters for lists are allowed.

DISTRACTOR QUALITY RULES (for multiple choice questions):
1. NEVER use placeholder text like "Incorrect option 1", "Incorrect option 2", "Incorrect option 3", "Wrong answer", "Distractor", or "Placeholder".
2. NEVER use phrases like "none of the above" or "all of the above".
   Do not use "All of the above", "None of the above", "Not applicable", "N/A", or single-letter options.
3. If a multiple choice question cannot be formed with four plausible, specific distractors from the source text, generate a different question instead.
4. ALWAYS generate specific, realistic distractors that are:
   - In the same category/domain as the correct answer
   - Plausible but clearly incorrect to knowledgeable students
   - Similar in length and complexity to the correct answer
   - Not obviously wrong (e.g., not "Blue" when the question is about historical dates)
5. All distractors must be unique and distinct from each other.
6. Distractors should test common misconceptions or related concepts.
7. EXAMPLE: If the question is "Who proclaimed the Philippine independence on June 12, 1898?" and the correct answer is "Emilio Aguinaldo", good distractors would be "Andres Bonifacio", "Jose Rizal", "Emilio Jacinto" - NOT "Incorrect option 1", "Wrong answer", etc.

QUESTION TYPE RULES:
- Multiple Choice: Output EXACTLY four options labelled A, B, C, and D. There must never be an E option. The correct answer must be one of A, B, C, or D.
- Identification: Output NO multiple-choice options. Provide the correct answer as a short phrase. The user will type the answer.
- Enumeration: Output NO multiple-choice options. Provide the correct answer as a numbered or comma-separated list of items.
- Mixed Format: Output a valid mixture of the three types above; each question must clearly follow its own type's rules.

8. Prefer returning a single JSON object when the user asks for it; otherwise follow the requested format exactly.''';
  }

  Future<String> _tryGenerateWithModel({
    required String model,
    required String prompt,
    required String systemMessage,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Groq API key is missing');
    }

    final client = Groq(
      apiKey: _apiKey!,
      configuration: _buildConfiguration(model),
    );

    // startChat must be called before any instruction or send
    client.startChat();
    client.setCustomInstructionsWith(systemMessage);

    if (kDebugMode) {
      developer.log('Groq request: model=$model, promptChars=${prompt.length}');
    }

    final response = await client.sendMessage(prompt).timeout(
      const Duration(seconds: 120),
      onTimeout: () {
        throw TimeoutException(
          'The AI request timed out after 120 seconds. Please try again or shorten the content.',
        );
      },
    );

    return response.choices.first.message.content;
  }

  Future<String> generateQuestions({
    required String content,
    required PromptTemplate template,
    required int questionCount,
    Map<String, String>? additionalVariables,
    String? model,
  }) async {
    if (!isInitialized) {
      throw Exception('Groq service not initialized. Please set API key first.');
    }

    final variables = {
      'content': content,
      'count': questionCount.toString(),
      'difficulty': template.difficulty.displayName.toLowerCase(),
      'number': questionCount.toString(),
      ...?additionalVariables,
    };

    final prompt = _templateRepository.buildPrompt(template, variables);
    final systemMessage = _buildSystemMessage(template);

    final modelChain = GroqModels.getFallbackChain(preferred: model ?? _currentModel);

    for (int i = 0; i < modelChain.length; i++) {
      final attemptModel = modelChain[i];
      try {
        final response = await _tryGenerateWithModel(
          model: attemptModel,
          prompt: prompt,
          systemMessage: systemMessage,
        );
        if (model != null && attemptModel != model) {
          _currentModel = attemptModel;
          _client = Groq(
            apiKey: _apiKey!,
            configuration: _buildConfiguration(attemptModel),
          );
        }
        return response;
      } on TimeoutException {
        rethrow;
      } catch (e) {
        if (kDebugMode) {
          developer.log('Groq model $attemptModel failed: $e');
        }
        if (i == modelChain.length - 1) {
          throw Exception('All Groq models failed: $e');
        }
      }
    }

    throw Exception('All Groq models failed');
  }

  Future<String> generateQuestionsWithBuiltInTemplate({
    required String content,
    required PromptType type,
    required int questionCount,
    Difficulty? difficulty,
    String? model,
  }) async {
    if (!isInitialized) {
      throw Exception('Groq service not initialized. Please set API key first.');
    }

    final templates = _templateRepository.getTemplatesByType(type);
    final template = templates.isNotEmpty 
        ? templates.first 
        : _templateRepository.builtInTemplates.first;

    final selectedDifficulty = difficulty ?? template.difficulty;

    return generateQuestions(
      content: content,
      template: template.copyWith(difficulty: selectedDifficulty),
      questionCount: questionCount,
      model: model,
    );
  }

  Future<String> generateExplanation({
    required String question,
    required String? userAnswer,
    required String correctAnswer,
    required QuestionType questionType,
    List<String>? options,
    String? model,
  }) async {
    if (!isInitialized) {
      throw Exception('Groq service not initialized. Please set API key first.');
    }

    // Update model if specified and different from current
    if (model != null && model != _currentModel) {
      _currentModel = model;
      final configuration = Configuration(model: _currentModel!);
      _client = Groq(apiKey: _apiKey!, configuration: configuration);
    }

    final typeLabel = _questionTypeLabel(questionType);
    final optionsText = (options != null && options.isNotEmpty)
        ? options
            .asMap()
            .entries
            .map((e) => '${String.fromCharCode(65 + e.key)}) ${e.value}')
            .join('\n')
        : '';

    final prompt = '''Question Type: $typeLabel
Question: $question
User's Answer: ${userAnswer ?? 'No answer'}
Correct Answer: $correctAnswer
${optionsText.isNotEmpty ? 'Options:\n$optionsText\n' : ''}

Determine whether the user's answer is correct by normalizing both answers: trim whitespace, ignore case, and ignore minor punctuation differences. For enumeration, compare the items as a set unless the question explicitly requires order. Treat "No Poverty" and "no poverty" as the same answer.

The user's answer may be wrong, incomplete, or missing. Do NOT treat it as correct. First state the correct answer. Then explain why the correct answer is right. If the user's answer is wrong, briefly explain why it is wrong. Always base the explanation on the Correct Answer above; never explain the user's answer as though it were correct.

${_questionTypeSpecificInstruction(questionType)}

Structure the explanation into short, readable paragraphs (1-3 sentences each).''';

    try {
      _client!.startChat();
      _client!.setCustomInstructionsWith(
        'You are an expert educator writing clear, readable study explanations for students. '
        'Use plain text only. Do NOT use Markdown headings (#), bold (**), underlines (__), '
        'fenced code blocks, or any other Markdown syntax. '
        'Structure your explanation into short, readable paragraphs separated by a single blank line. '
        'You may use simple numbered lists (1. 2. 3.) or bullet lists (- ) when listing distinct reasons. '
        'Keep each paragraph to 1-3 sentences. Be direct, specific, and student-friendly. '
        'Do not write robotic openings such as "As an AI", "The correct answer is", '
        '"Here is the explanation", or similar phrases. Start directly with the explanation.',
      );
      final response = await _client!.sendMessage(prompt);
      return response.choices.first.message.content;
    } catch (e) {
      throw Exception('Failed to generate explanation: $e');
    }
  }

  String _questionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.identification:
        return 'Identification';
      case QuestionType.enumeration:
        return 'Enumeration';
      case QuestionType.mixedFormat:
        return 'Mixed Format';
    }
  }

  String _questionTypeSpecificInstruction(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Explain why the correct option is correct and briefly why each distractor is incorrect.';
      case QuestionType.identification:
        return 'Explain why the correct answer is correct and compare it with the user\'s answer.';
      case QuestionType.enumeration:
        return 'Explain the set of correct items and point out any missing or incorrect items in the user\'s list.';
      case QuestionType.mixedFormat:
        return 'Explain why the correct answer is correct and compare it with the user\'s answer.';
    }
  }

  Future<String> generateFlashcardContent({
    required String topic,
    required String content,
    int cardCount = 10,
    String? model,
  }) async {
    if (!isInitialized) {
      throw Exception('Groq service not initialized. Please set API key first.');
    }

    // Update model if specified and different from current
    if (model != null && model != _currentModel) {
      _currentModel = model;
      final configuration = Configuration(model: _currentModel!);
      _client = Groq(apiKey: _apiKey!, configuration: configuration);
    }

    final prompt = '''You are an expert educator. Based on the following content about "$topic", create $cardCount flashcards.

Requirements:
- Each flashcard should have a clear question on the front
- The back should have a concise answer
- Cover key concepts, definitions, and important facts
- Make questions progressively more challenging

Content:
$content

Format each flashcard as:
FRONT: [question]
BACK: [answer]''';

    try {
      _client!.startChat();
      final response = await _client!.sendMessage(prompt);
      return response.choices.first.message.content;
    } catch (e) {
      throw Exception('Failed to generate flashcard content: $e');
    }
  }

  Future<String> summarizeContent({
    required String content,
    int maxLength = 200,
    String? model,
  }) async {
    if (!isInitialized) {
      throw Exception('Groq service not initialized. Please set API key first.');
    }

    // Update model if specified and different from current
    if (model != null && model != _currentModel) {
      _currentModel = model;
      final configuration = Configuration(model: _currentModel!);
      _client = Groq(apiKey: _apiKey!, configuration: configuration);
    }

    final prompt = '''Summarize the following content in approximately $maxLength words. Focus on the key points and main ideas.

Content:
$content''';

    try {
      _client!.startChat();
      final response = await _client!.sendMessage(prompt);
      return response.choices.first.message.content;
    } catch (e) {
      throw Exception('Failed to summarize content: $e');
    }
  }

  void clearApiKey() {
    _apiKey = null;
    _client = null;
    _currentModel = null;
  }
}
