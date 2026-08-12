import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/prompt_template.dart';

class PromptTemplateRepository {
  static const String _customPromptsKey = 'custom_prompt_templates';

  List<PromptTemplate> _builtInTemplates = [];
  List<PromptTemplate> _customTemplates = [];

  List<PromptTemplate> get allTemplates => [..._builtInTemplates, ..._customTemplates];
  List<PromptTemplate> get builtInTemplates => _builtInTemplates;
  List<PromptTemplate> get customTemplates => _customTemplates;

  Future<void> initialize() async {
    await _loadBuiltInTemplates();
    await _loadCustomTemplates();
  }

  Future<void> _loadBuiltInTemplates() async {
    _builtInTemplates = [
      // Multiple Choice Template
      PromptTemplate(
        id: 'builtin_multiple_choice',
        name: 'Multiple Choice Questions',
        description: 'Generate multiple-choice questions with 4 choices and one correct answer.',
        template: '''You are an expert educator. Based on the following study material, generate {count} multiple-choice questions.

Requirements:
- Each question must have exactly 4 options (A, B, C, D)
- Only one correct answer per question
- Questions should test understanding, not just memorization
- Include a brief explanation for the correct answer
- Difficulty level: {difficulty}

Study Material:
{content}

Format each question as:
Question: [question text]
A) [option A]
B) [option B]
C) [option C]
D) [option D]
Correct Answer: [letter]
Explanation: [why this is correct]''',
        type: PromptType.multipleChoice,
        difficulty: Difficulty.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),

      // Identification Template
      PromptTemplate(
        id: 'builtin_identification',
        name: 'Identification Questions',
        description: 'Generate short-answer identification questions with concise answers.',
        template: '''You are an expert educator. Based on the following study material, generate {count} identification questions.

Requirements:
- Questions should ask for specific terms, concepts, or definitions
- Answers should be concise (1-3 sentences maximum)
- Focus on key terminology and important concepts
- Difficulty level: {difficulty}

Study Material:
{content}

Format each question as:
Question: [question text]
Answer: [concise answer]''',
        type: PromptType.identification,
        difficulty: Difficulty.easy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),

      // Enumeration Template
      PromptTemplate(
        id: 'builtin_enumeration',
        name: 'Enumeration Questions',
        description: 'Generate enumeration questions requiring a list of key points.',
        template: '''You are an expert educator. Based on the following study material, generate {count} enumeration questions.

Requirements:
- Questions should ask for lists of items, steps, characteristics, etc.
- Specify the number of items expected
- Items should be distinct and meaningful
- Difficulty level: {difficulty}

Study Material:
{content}

Format each question as:
Question: [question text] (List {number} items)
Answer:
1. [item 1]
2. [item 2]
3. [item 3]
...''',
        type: PromptType.enumeration,
        difficulty: Difficulty.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),

      // Exam Simulation Template
      PromptTemplate(
        id: 'builtin_exam_simulation',
        name: 'Exam Simulation',
        description: 'Generate board-exam-style questions with moderate to high difficulty.',
        template: '''You are an expert exam creator. Based on the following study material, generate a comprehensive exam with {count} questions.

Requirements:
- Mix of multiple-choice, identification, and enumeration questions
- Moderate to high difficulty level
- Questions should simulate real board exam conditions
- Include scenario-based questions when applicable
- Difficulty level: {difficulty}

Study Material:
{content}

Format each question clearly with its type and instructions.
Include an answer key at the end.''',
        type: PromptType.examSimulation,
        difficulty: Difficulty.hard,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),

      // Explanation Template
      PromptTemplate(
        id: 'builtin_explanation',
        name: 'Explanation Questions',
        description: 'Generate questions that require detailed explanations of concepts.',
        template: '''You are an expert educator. Based on the following study material, generate {count} explanation questions.

Requirements:
- Questions should require detailed, thoughtful responses
- Focus on "why" and "how" rather than "what"
- Answers should demonstrate deep understanding
- Include guidance on key points to cover
- Difficulty level: {difficulty}

Study Material:
{content}

Format each question as:
Question: [question text]
Key Points to Cover:
- [point 1]
- [point 2]
- [point 3]
Sample Answer Framework: [brief structure]''',
        type: PromptType.explanation,
        difficulty: Difficulty.hard,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),

      // Study Deck Master Template
      PromptTemplate(
        id: 'builtin_study_deck',
        name: 'Study Deck Generator',
        description: 'Generate comprehensive study decks with mixed question types and detailed formatting.',
        template: '''You are an expert educational assessor, exam designer, and master human tutor.

CRITICAL FORMATTING & HUMANIZATION CONSTRAINTS:
1. STRICTLY ZERO MARKDOWN SYMBOLS: Do NOT use asterisks (**), hashtags (##), double dashes (--), underscores (__), or HTML tags. Use plain text, standard numbered lists (1, 2, 3), clean spacing, and standard punctuation only.
2. HUMAN WRITING TONE: Write naturally as a human teacher. Do NOT write robotic setup or filler sentences (never write "Here is your exam" or "Based on the provided document"). Avoid AI buzzwords like "delve," "tapestry," "leverage," "crucial," or "fostering."
3. ATOMIC QUESTIONS: Every item must focus on a single concept. Keep answers concise (1 to 3 sentences or a clean numbered list).

QUESTION TYPES & DISTRIBUTION RULES:
Incorporate a mix of these 4 formats across every deck:
- Multiple Choice: 4 options (A, B, C, D) with 1 correct answer and 3 realistic distractors.
- Identification: Direct prompt or definition asking for a specific term, date, or concept.
- Enumeration: Prompt requiring a list of 2 to 5 specific items, criteria, or steps.
- Explanation / Free-Response: Conceptual question requiring a natural, plain-text explanation.

MULTI-ANGLE & VOLUME STRATEGY:
When testing a primary concept multiple times, do NOT write duplicate questions. Approach the concept from distinct angles across items (e.g., Card 1: Definition/What, Card 2: Mechanism/How, Card 3: Real-world Scenario, Card 4: Compare/Contrast with a related term).

DIFFICULTY TIERS:
Label every item with its difficulty level: [Easy], [Medium], or [Hard].

OUTPUT STRUCTURE (EXAM SIMULATION):
Always divide the output into two distinct sections using clean line breaks:

SECTION 1: STUDY FLASHCARDS AND EXAM PAPER
List all questions sequentially without revealing answers.

Format:
Item [Number] | [Question Type] | [Difficulty Tier]
Question Prompt: [Write the prompt here]
Options (if Multiple Choice):
A) [Option 1]
B) [Option 2]
C) [Option 3]
D) [Option 4]

SECTION 2: ANSWER KEY AND EXPLANATIONS
Provide full answers corresponding to Section 1.

Format:
Item [Number] Answer: [Correct Answer / Key Terms / Enumerated Points]
Explanation: [Natural explanation of why this is correct. For Multiple Choice, state why key distractors are incorrect.]

Generate {count} study deck items from the source material below.

Source Material:
{content}''',
        type: PromptType.studyDeck,
        difficulty: Difficulty.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isBuiltIn: true,
      ),
    ];
  }

  Future<void> _loadCustomTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final templatesJson = prefs.getString(_customPromptsKey);
    
    if (templatesJson != null) {
      try {
        final List<dynamic> decoded = json.decode(templatesJson);
        _customTemplates = decoded
            .map((json) => PromptTemplate.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error loading custom templates: $e');
        _customTemplates = [];
      }
    }
  }

  Future<void> _saveCustomTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final templatesJson = json.encode(
      _customTemplates.map((t) => t.toJson()).toList(),
    );
    await prefs.setString(_customPromptsKey, templatesJson);
  }

  Future<void> addCustomTemplate(PromptTemplate template) async {
    final newTemplate = template.copyWith(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isBuiltIn: false,
    );
    _customTemplates.add(newTemplate);
    await _saveCustomTemplates();
  }

  Future<void> updateCustomTemplate(PromptTemplate template) async {
    final index = _customTemplates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _customTemplates[index] = template.copyWith(
        updatedAt: DateTime.now(),
      );
      await _saveCustomTemplates();
    }
  }

  Future<void> deleteCustomTemplate(String id) async {
    _customTemplates.removeWhere((t) => t.id == id);
    await _saveCustomTemplates();
  }

  PromptTemplate? getTemplateById(String id) {
    try {
      return allTemplates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  List<PromptTemplate> getTemplatesByType(PromptType type) {
    return allTemplates.where((t) => t.type == type).toList();
  }

  List<PromptTemplate> getTemplatesByDifficulty(Difficulty difficulty) {
    return allTemplates.where((t) => t.difficulty == difficulty).toList();
  }

  String buildPrompt(PromptTemplate template, Map<String, String> variables) {
    String prompt = template.template;
    
    variables.forEach((key, value) {
      prompt = prompt.replaceAll('{$key}', value);
    });
    
    return prompt;
  }
}