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
- Questions should ask for a specific term, date, place, name, or definition
- Answers must be 1-2 words whenever possible, and never exceed 4 words
- Do NOT return full sentences, explanations, or articles ("the", "a", "an")
- If the answer is a sentence, extract only the key term
- Difficulty level: {difficulty}

Study Material:
{content}

Format each question as:
Question: [question text]
Answer: [1-2 word answer]''',
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
- Each item must be 1-3 words only (use names, places, foods, terms, or short phrases)
- Do NOT use explanatory sentences; each line should be a list item only
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

      // Mixed Format Template (JSON) - one of each type per batch
      PromptTemplate(
        id: 'builtin_mixed_format',
        name: 'Mixed Question Formats',
        description: 'Generate a mix of multiple choice, identification, and enumeration items in one request.',
        template: '''Return ONLY a single JSON object with no Markdown and no extra commentary. Use this exact structure:

{
  "questions": [
    {
      "type": "multiple_choice",
      "difficulty": "[Medium]",
      "question": "...",
      "options": ["A) ...", "B) ...", "C) ...", "D) ..."],
      "answer": "A",
      "explanation": "..."
    },
    {
      "type": "identification",
      "difficulty": "[Easy]",
      "question": "...",
      "answer": "...",
      "explanation": "..."
    },
    {
      "type": "enumeration",
      "difficulty": "[Medium]",
      "question": "...",
      "options": ["item 1", "item 2"],
      "answer": "item 1, item 2",
      "explanation": "..."
    }
  ]
}

CRITICAL MIXED FORMAT RULES:
- This is MIXED FORMAT. You MUST generate a combination of all three question types in the same response: multiple_choice, identification, AND enumeration.
- Do NOT generate only one question type. A response containing only multiple_choice questions is NOT mixed format and will be rejected.
- Distribute the {count} questions across all three types as evenly as possible:
  - For {count} = 3: 1 multiple_choice, 1 identification, 1 enumeration.
  - For {count} = 6: 2 of each type.
  - For {count} = 9: 3 of each type.
  - For counts not divisible by 3, give the extra questions to multiple_choice first, then identification, then enumeration. Never omit a type when {count} >= 3.
  - Example: {count} = 4 -> 2 multiple_choice, 1 identification, 1 enumeration.
  - Example: {count} = 5 -> 2 multiple_choice, 2 identification, 1 enumeration.
- Each question must use the structure for its own type:
  - multiple_choice: exactly 4 options and one correct letter A-D.
  - identification: NO options; a short answer (1-3 words when possible).
  - enumeration: NO A-D options; "options" holds the list items and "answer" is the comma-joined items.
- Vary angles: definition, mechanism, application, compare/contrast, cause/effect, process/sequence.
- Avoid duplicates and compound questions.
- All questions must remain grounded in the source material.

Source Material:
{content}''',
        type: PromptType.mixedFormat,
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