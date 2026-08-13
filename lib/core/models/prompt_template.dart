class PromptTemplate {
  final String id;
  final String name;
  final String description;
  final String template;
  final PromptType type;
  final Difficulty difficulty;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isBuiltIn;

  PromptTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.template,
    required this.type,
    required this.difficulty,
    required this.createdAt,
    required this.updatedAt,
    this.isBuiltIn = false,
  });

  PromptTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? template,
    PromptType? type,
    Difficulty? difficulty,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isBuiltIn,
  }) {
    return PromptTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      template: template ?? this.template,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'template': template,
      'type': type.toString(),
      'difficulty': difficulty.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isBuiltIn': isBuiltIn,
    };
  }

  factory PromptTemplate.fromJson(Map<String, dynamic> json) {
    return PromptTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      template: json['template'] as String,
      type: PromptType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => PromptType.multipleChoice,
      ),
      difficulty: Difficulty.values.firstWhere(
        (e) => e.toString() == json['difficulty'],
        orElse: () => Difficulty.medium,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }
}

enum PromptType {
  multipleChoice,
  identification,
  enumeration,
  mixedFormat,
}

enum Difficulty {
  easy,
  medium,
  hard,
  expert,
}

extension PromptTypeExtension on PromptType {
  String get displayName {
    switch (this) {
      case PromptType.multipleChoice:
        return 'Multiple Choice';
      case PromptType.identification:
        return 'Identification';
      case PromptType.enumeration:
        return 'Enumeration';
      case PromptType.mixedFormat:
        return 'Mixed Format';
    }
  }

  String get icon {
    switch (this) {
      case PromptType.multipleChoice:
        return '📝';
      case PromptType.identification:
        return '🔍';
      case PromptType.enumeration:
        return '📋';
      case PromptType.mixedFormat:
        return '🎲';
    }
  }
}

extension DifficultyExtension on Difficulty {
  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.expert:
        return 'Expert';
    }
  }

  String get description {
    switch (this) {
      case Difficulty.easy:
        return 'Basic concepts and definitions';
      case Difficulty.medium:
        return 'Moderate complexity questions';
      case Difficulty.hard:
        return 'Advanced and challenging questions';
      case Difficulty.expert:
        return 'Board-exam level difficulty';
    }
  }
}