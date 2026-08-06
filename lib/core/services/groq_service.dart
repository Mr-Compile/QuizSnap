import 'package:groq/groq.dart';
import '../models/prompt_template.dart';
import '../repositories/prompt_template_repository.dart';

class GroqService {
  static const String _defaultModel = 'llama3-70b-8192';
  
  String? _apiKey;
  Groq? _client;
  final PromptTemplateRepository _templateRepository = PromptTemplateRepository();

  bool get isInitialized => _apiKey != null && _client != null;

  Future<void> initialize(String apiKey) async {
    _apiKey = apiKey;
    _client = Groq(apiKey: apiKey);
    await _templateRepository.initialize();
  }

  Future<String> generateQuestions({
    required String content,
    required PromptTemplate template,
    required int questionCount,
    Map<String, String>? additionalVariables,
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

    try {
      final response = await _client!.chat.completions.create(
        model: _defaultModel,
        messages: [
          ChatMessage(
            role: ChatMessageRole.user,
            content: prompt,
          ),
        ],
        temperature: 0.7,
        maxTokens: 2048,
      );

      return response.choices.first.message.content ?? '';
    } catch (e) {
      throw Exception('Failed to generate questions: $e');
    }
  }

  Future<String> generateQuestionsWithBuiltInTemplate({
    required String content,
    required PromptType type,
    required int questionCount,
    Difficulty? difficulty,
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
    );
  }

  Future<String> generateExplanation({
    required String question,
    required String correctAnswer,
    required List<String> wrongAnswers,
  }) async {
    if (!isInitialized) {
      throw Exception('Groq service not initialized. Please set API key first.');
    }

    final prompt = '''You are an expert educator. Explain why the correct answer is correct and why the other options are incorrect.

Question: $question
Correct Answer: $correctAnswer
Wrong Answers: ${wrongAnswers.join(', ')}

Provide a clear, concise explanation that helps students understand the concept.''';

    try {
      final response = await _client!.chat.completions.create(
        model: _defaultModel,
        messages: [
          ChatMessage(
            role: ChatMessageRole.user,
            content: prompt,
          ),
        ],
        temperature: 0.5,
        maxTokens: 500,
      );

      return response.choices.first.message.content ?? '';
    } catch (e) {
      throw Exception('Failed to generate explanation: $e');
    }
  }

  Future<String> generateFlashcardContent({
    required String topic,
    required String content,
    int cardCount = 10,
  }) async {
    if (!isInitialized) {
      throw Exception('Groq service not initialized. Please set API key first.');
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
      final response = await _client!.chat.completions.create(
        model: _defaultModel,
        messages: [
          ChatMessage(
            role: ChatMessageRole.user,
            content: prompt,
          ),
        ],
        temperature: 0.7,
        maxTokens: 2048,
      );

      return response.choices.first.message.content ?? '';
    } catch (e) {
      throw Exception('Failed to generate flashcard content: $e');
    }
  }

  Future<String> summarizeContent({
    required String content,
    int maxLength = 200,
  }) async {
    if (!isInitialized) {
      throw Exception('Groq service not initialized. Please set API key first.');
    }

    final prompt = '''Summarize the following content in approximately $maxLength words. Focus on the key points and main ideas.

Content:
$content''';

    try {
      final response = await _client!.chat.completions.create(
        model: _defaultModel,
        messages: [
          ChatMessage(
            role: ChatMessageRole.user,
            content: prompt,
          ),
        ],
        temperature: 0.5,
        maxTokens: 300,
      );

      return response.choices.first.message.content ?? '';
    } catch (e) {
      throw Exception('Failed to summarize content: $e');
    }
  }

  void clearApiKey() {
    _apiKey = null;
    _client = null;
  }
}