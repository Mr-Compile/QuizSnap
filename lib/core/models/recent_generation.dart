import 'prompt_template.dart';

/// Metadata for a recent AI generation session.
class RecentGeneration {
  final String id;
  final String title;
  final String sourceFile;
  final DateTime generatedAt;
  final int questionCount;
  final int? savedDeckId;
  final List<Map<String, dynamic>> questionsJson;
  final PromptType type;
  final Difficulty difficulty;
  final QuestionStyle style;
  final String sourceText;

  RecentGeneration({
    required this.id,
    required this.title,
    required this.sourceFile,
    required this.generatedAt,
    required this.questionCount,
    this.savedDeckId,
    required this.questionsJson,
    required this.type,
    required this.difficulty,
    this.style = QuestionStyle.distractors,
    this.sourceText = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sourceFile': sourceFile,
        'generatedAt': generatedAt.toIso8601String(),
        'questionCount': questionCount,
        'savedDeckId': savedDeckId,
        'questionsJson': questionsJson,
        'typeIndex': type.index,
        'difficultyIndex': difficulty.index,
        'styleIndex': style.index,
        'sourceText': sourceText,
      };

  factory RecentGeneration.fromJson(Map<String, dynamic> json) {
    return RecentGeneration(
      id: json['id'] as String,
      title: json['title'] as String,
      sourceFile: json['sourceFile'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      questionCount: json['questionCount'] as int,
      savedDeckId: json['savedDeckId'] as int?,
      questionsJson: List<Map<String, dynamic>>.from(json['questionsJson'] as List? ?? []),
      type: PromptType.values[json['typeIndex'] as int? ?? 0],
      difficulty: Difficulty.values[json['difficultyIndex'] as int? ?? 1],
      style: QuestionStyle.values[json['styleIndex'] as int? ?? 0],
      sourceText: json['sourceText'] as String? ?? '',
    );
  }

  RecentGeneration copyWith({
    String? title,
    int? savedDeckId,
  }) {
    return RecentGeneration(
      id: id,
      title: title ?? this.title,
      sourceFile: sourceFile,
      generatedAt: generatedAt,
      questionCount: questionCount,
      savedDeckId: savedDeckId ?? this.savedDeckId,
      questionsJson: questionsJson,
      type: type,
      difficulty: difficulty,
      style: style,
      sourceText: sourceText,
    );
  }
}
