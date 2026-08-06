import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/prompt_template.dart';

class PromptTemplateRepository {
  static const String _promptsKey = 'prompt_templates';
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
        print('Error loading custom templates: $e');
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