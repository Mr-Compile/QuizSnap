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

  String _buildSystemMessage(PromptTemplate template, {QuestionStyle style = QuestionStyle.distractors}) {
    final distractorsSection = style == QuestionStyle.distractors
        ? '''

WITH DISTRACTORS QUESTION STYLE RULES:
1. Generate a direct Multiple Choice question based on the provided learning material. Ask the question straight — do NOT wrap it in a scenario.
2. The question must be grounded in the source material and answerable using it.
3. The question should test understanding, knowledge, or application appropriate to the selected difficulty.
4. Do NOT invent unsupported facts.
5. Create exactly 4 options (A, B, C, D) with ONE correct answer and THREE plausible distractors.
6. Distractors must be related to the same topic and represent common misconceptions, closely related concepts, or plausible alternatives.
7. Do NOT use random or unrelated answers, "none/all of the above", obviously ridiculous choices, or trick wording.
8. Options must be grammatically consistent and reasonably similar in structure and length. Do not reveal the correct answer through wording or length.
9. The explanation must explain why the correct answer is correct based on the source material — not why a scenario leads to it.
10. For Identification: ask a direct question whose answer is a short term/phrase from the source.
11. For Enumeration: ask a direct question whose answer is a list of items from the source.
12. For Mixed Format: each question adapts to its own type using the direct (non-scenario) style above.'''
        : '';

    final situationalSection = style == QuestionStyle.situational
        ? '''

SITUATIONAL QUESTION STYLE RULES:
1. Every question MUST present a realistic situation or scenario. The student should encounter a problem, event, decision, task, or circumstance before being asked the question.
2. The scenario must require the student to APPLY the learning material, not merely recognize or recall a definition. The student should need to identify, choose, recommend, apply, determine, prioritize, classify, evaluate, troubleshoot, or decide based on the situation.
3. DO NOT write simple recall questions such as "What is X?", "What does X mean?", "Which of the following defines X?", "Who is X?", or "What is the purpose of X?" unless the source material genuinely makes factual recall necessary.
4. DO NOT turn a normal definition question into a fake scenario. Bad: "A student is studying risk management. What is risk assessment?" — this is still a recall question. Instead, describe a situation where the concept is being applied.
5. The scenario must contain enough information for the student to reason toward the answer. Do not make the scenario unnecessarily long just to make the question appear situational. A situational question is NOT simply a long story.
6. The situation must be realistic and believable within the subject being studied. Use contexts appropriate to the subject (education: student/teacher/classroom; business: employee/manager/organization; IT: developer/administrator/system; etc.). Do not force a context if it is unrelated to the source material.
7. Vary the scenario openings. Do NOT start every question with "A student encounters...". Use varied openings: "A teacher needs to...", "A school plans to...", "A developer notices...", "A company experiences...", "An administrator discovers...", "A user attempts to...", "During implementation...", "While reviewing the system...", "After an unexpected failure...", "Given the following situation...", "An organization is deciding...", "A team is preparing...", "During a project...", "A customer reports...", "Before deployment...".
8. DO NOT give away the answer in the scenario. Bad: "The administrator performs risk assessment by evaluating... What process is this?" Instead: "The administrator evaluates the likelihood and potential impact of each identified risk before deciding how to respond. Which risk-management activity is being performed?"
9. The question should NOT be solvable simply by spotting a keyword. The student must connect: Scenario -> Relevant information -> Concept from the learning material -> Reasoning -> Best answer.

SOURCE-GROUNDED SCENARIO RULES:
1. Every scenario MUST be grounded in the uploaded learning material. The concept being tested MUST come from the source material.
2. The AI may create realistic context around a concept from the source, but must NOT introduce unsupported facts that change the meaning of the concept.
3. Do NOT invent statistics, laws, policies, technical specifications, historical facts, procedures, terminology, people, organizations, or outcomes that are not supported by the learning material unless they are clearly generic scenario context.
4. The scenario is a context for applying the material, not an excuse to introduce unrelated knowledge. The question must be answerable using the provided learning material.
5. If the source material does not provide enough information to construct a valid situational question, do not fabricate an answer.

DIFFICULTY RULES:
- Easy: Require straightforward application. The scenario should contain enough information that the correct concept/action is relatively clear.
- Medium: Require interpretation. The student must understand the situation and determine which concept or action applies.
- Hard: Require comparison, judgment, prioritization, or evaluation. The student must consider multiple plausible alternatives and determine the best answer. Do NOT make a question "Hard" merely by making the scenario longer — hard questions should require better reasoning.

DISTRACTOR RULES FOR SITUATIONAL MCQ:
1. Each question MUST have exactly 4 options (A, B, C, D) with exactly 1 correct answer and exactly 3 plausible distractors.
2. Distractors must be related to the scenario AND the source material. They should represent plausible alternatives, common misconceptions, or closely related concepts.
3. Distractors must be clearly incorrect when the scenario is properly understood, but not obviously ridiculous.
4. Distractors must have grammatically consistent wording and reasonably similar length and structure to the correct answer. They must NOT reveal the correct answer through wording.
5. Do NOT use "All of the above", "None of the above", "Both A and B", or trick wording.

SINGLE BEST ANSWER RULE:
1. Situational questions must have ONE clearly best answer. Do NOT create questions where multiple options could be correct. If multiple options appear technically possible, revise the scenario so the source material clearly supports one best answer.
2. The correct answer must be supported by the uploaded material, not merely by general AI knowledge.

EXPLANATION RULES:
1. Every question MUST include an explanation.
2. The explanation must identify WHY the correct answer fits the situation, connect the scenario to the source material, and explain the reasoning rather than merely defining the concept.
3. Do NOT treat an incorrect student answer as correct. Do NOT produce a bare definition like "Risk assessment means evaluating risks." — explain the reasoning.
4. Preserve paragraphs and meaningful newlines in the explanation.

TYPE-SPECIFIC ADAPTATION:
- For Multiple Choice: the scenario leads into the question; the four options are plausible distractors plus one correct answer; the explanation ties back to the scenario.
- For Identification: the scenario describes a situation, and the answer is the specific term/concept being demonstrated.
- For Enumeration: the scenario sets up a situation that requires listing the relevant items from the source material.
- For Mixed Format: each question adapts its style to its actual type as described above.'''
        : '';

    return '''You are an expert educator writing study content for a Flutter flashcard app.

CRITICAL OUTPUT RULES:
1. NO MARKDOWN. Do not use **, ##, __, leading bullets (- or *), fenced code blocks, or any Markdown.
2. Write like a real human instructor. Do not write "Here is your exam", "The following questions are generated", "As an AI", or similar robotic openings.
3. Avoid buzzwords: delve, leverage, tapestry, crucial, fostering.
4. Every item must be ATOMIC: one concept per item, short answer (1-3 sentences), concise lists for enumeration.
5. Each item must be labeled with a difficulty: [Easy], [Medium], or [Hard].
6. Use plain text only. Numbers and letters for lists are allowed.
$distractorsSection$situationalSection

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
    QuestionStyle style = QuestionStyle.distractors,
    String? promptPrefix,
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

    var prompt = _templateRepository.buildPrompt(template, variables);
    if (promptPrefix != null && promptPrefix.isNotEmpty) {
      prompt = '$promptPrefix\n\n$prompt';
    }
    final styledPrompt = _applyStyleToPrompt(prompt, template.type, style);
    final systemMessage = _buildSystemMessage(template, style: style);

    final modelChain = GroqModels.getFallbackChain(preferred: model ?? _currentModel);

    for (int i = 0; i < modelChain.length; i++) {
      final attemptModel = modelChain[i];
      try {
        final response = await _tryGenerateWithModel(
          model: attemptModel,
          prompt: styledPrompt,
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

  /// Prepends style-specific instructions to the rendered prompt so the AI
  /// knows whether to write With Distractors or Situational questions. The
  /// original template content is preserved; only a short directive is added.
  String _applyStyleToPrompt(String prompt, PromptType type, QuestionStyle style) {
    if (style == QuestionStyle.distractors) {
      final buffer = StringBuffer()
        ..writeln('QUESTION STYLE: WITH DISTRACTORS')
        ..writeln(
          'Generate a direct Multiple Choice question based on the provided learning material. Ask the question straight — do NOT wrap it in a scenario.',
        )
        ..writeln(
          'The question must be grounded in the source material and answerable using it. Do NOT invent unsupported facts.',
        )
        ..writeln(
          'Create exactly 4 options (A, B, C, D) with ONE correct answer and THREE plausible distractors. Distractors must be related to the same topic and represent common misconceptions, closely related concepts, or plausible alternatives.',
        )
        ..writeln(
          'Do NOT use random or unrelated answers, "none/all of the above", obviously ridiculous choices, or trick wording. Options must be grammatically consistent and reasonably similar in structure and length. Do not reveal the correct answer through wording or length.',
        )
        ..writeln(
          'For Identification: ask a direct question whose answer is a short term/phrase from the source.',
        )
        ..writeln(
          'For Enumeration: ask a direct question whose answer is a list of items from the source.',
        )
        ..writeln(
          'For Mixed Format: each question adapts to its own type using the direct (non-scenario) style above.',
        )
        ..writeln(
          'The explanation must explain why the correct answer is correct based on the source material — not why a scenario leads to it.',
        )
        ..writeln()
        ..writeln(prompt);
      return buffer.toString();
    }

    final buffer = StringBuffer()
      ..writeln('QUESTION STYLE: SITUATIONAL')
      ..writeln(
        'Generate SITUATIONAL, application-based questions. Every question MUST present a realistic situation or scenario grounded in the source material, then ask the student to identify, choose, recommend, apply, determine, prioritize, classify, evaluate, troubleshoot, or decide.',
      )
      ..writeln(
        'Do NOT write simple recall questions such as "What is X?", "What does X mean?", "Which of the following defines X?", "Who is X?", or "What is the purpose of X?" unless the source material genuinely requires factual recall. Do NOT turn a definition question into a fake scenario by prepending "A student is studying..." — describe a situation where the concept is actually applied.',
      )
      ..writeln(
        'The scenario must contain enough information to reason toward the answer, but must NOT be unnecessarily long. A situational question is NOT simply a long story. Do NOT give away the answer in the scenario (e.g., do NOT write "The administrator performs risk assessment by...").',
      )
      ..writeln(
        'The scenario MUST be grounded in the uploaded material. The concept being tested MUST come from the source. Do NOT invent statistics, laws, policies, technical specs, historical facts, procedures, terminology, people, organizations, or outcomes not supported by the learning material. The question must be answerable using the provided learning material.',
      )
      ..writeln(
        'Vary the scenario openings. Do NOT start every question with "A student encounters...". Use varied openings: "A teacher needs to...", "A school plans to...", "A developer notices...", "A company experiences...", "An administrator discovers...", "A user attempts to...", "During implementation...", "While reviewing the system...", "After an unexpected failure...", "Given the following situation...", "An organization is deciding...", "A team is preparing...", "During a project...", "A customer reports...", "Before deployment...".',
      )
      ..writeln(
        'Difficulty: Easy = straightforward application (the correct action is relatively clear); Medium = interpretation (the student must determine which concept applies); Hard = comparison/judgment/prioritization (the student must weigh alternatives). Do NOT make a question hard merely by making the scenario longer.',
      )
      ..writeln(
        'For Multiple Choice: exactly 4 options (A, B, C, D) with ONE correct answer and THREE plausible distractors. Distractors must be related to the scenario and source, represent common misconceptions or related concepts, be clearly incorrect when the scenario is understood, and be similar in length and structure. Do NOT use "all/none of the above" or trick wording. The question must have ONE clearly best answer supported by the uploaded material.',
      )
      ..writeln(
        'For Identification: the scenario describes a situation, and the answer is the specific term/concept being demonstrated.',
      )
      ..writeln(
        'For Enumeration: the scenario sets up a situation that requires listing the relevant items from the source material.',
      )
      ..writeln(
        'For Mixed Format: each question adapts its style to its actual type — multiple choice, identification, and enumeration all become situational.',
      )
      ..writeln(
        'The explanation MUST identify WHY the correct answer fits the situation, connect the scenario to the source material, and explain the reasoning — not merely define the concept. Do NOT treat an incorrect answer as correct.',
      )
      ..writeln()
      ..writeln(prompt);
    return buffer.toString();
  }

  Future<String> generateQuestionsWithBuiltInTemplate({
    required String content,
    required PromptType type,
    required int questionCount,
    Difficulty? difficulty,
    QuestionStyle style = QuestionStyle.distractors,
    String? promptPrefix,
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
      style: style,
      promptPrefix: promptPrefix,
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
        return 'Explain why the correct option is correct and briefly why each distractor is incorrect. If the question describes a scenario, tie the explanation back to that scenario.';
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
