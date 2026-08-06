enum ExportFormat {
  pdf,
  csv,
  json,
}

enum ExportType {
  flashcards,
  quiz,
  answerKey,
  studyPack,
  backup,
}

enum ExportStatus {
  pending,
  generating,
  completed,
  failed,
}

class ExportOptions {
  final ExportFormat format;
  final ExportType type;
  final bool includeAnswers;
  final bool includeExplanations;
  final bool includeTags;
  final bool shuffleQuestions;
  final int? questionLimit;
  final String? customTitle;
  final String? customDescription;

  ExportOptions({
    required this.format,
    required this.type,
    this.includeAnswers = true,
    this.includeExplanations = false,
    this.includeTags = false,
    this.shuffleQuestions = false,
    this.questionLimit,
    this.customTitle,
    this.customDescription,
  });

  ExportOptions copyWith({
    ExportFormat? format,
    ExportType? type,
    bool? includeAnswers,
    bool? includeExplanations,
    bool? includeTags,
    bool? shuffleQuestions,
    int? questionLimit,
    String? customTitle,
    String? customDescription,
  }) {
    return ExportOptions(
      format: format ?? this.format,
      type: type ?? this.type,
      includeAnswers: includeAnswers ?? this.includeAnswers,
      includeExplanations: includeExplanations ?? this.includeExplanations,
      includeTags: includeTags ?? this.includeTags,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      questionLimit: questionLimit ?? this.questionLimit,
      customTitle: customTitle ?? this.customTitle,
      customDescription: customDescription ?? this.customDescription,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'format': format.toString(),
      'type': type.toString(),
      'includeAnswers': includeAnswers,
      'includeExplanations': includeExplanations,
      'includeTags': includeTags,
      'shuffleQuestions': shuffleQuestions,
      'questionLimit': questionLimit,
      'customTitle': customTitle,
      'customDescription': customDescription,
    };
  }

  factory ExportOptions.fromJson(Map<String, dynamic> json) {
    return ExportOptions(
      format: ExportFormat.values.firstWhere(
        (e) => e.toString() == json['format'],
        orElse: () => ExportFormat.pdf,
      ),
      type: ExportType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ExportType.flashcards,
      ),
      includeAnswers: json['includeAnswers'] as bool? ?? true,
      includeExplanations: json['includeExplanations'] as bool? ?? false,
      includeTags: json['includeTags'] as bool? ?? false,
      shuffleQuestions: json['shuffleQuestions'] as bool? ?? false,
      questionLimit: json['questionLimit'] as int?,
      customTitle: json['customTitle'] as String?,
      customDescription: json['customDescription'] as String?,
    );
  }
}

class ExportResult {
  final String id;
  final ExportOptions options;
  final ExportStatus status;
  final String? filePath;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? fileSizeBytes;

  ExportResult({
    required this.id,
    required this.options,
    required this.status,
    this.filePath,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
    this.fileSizeBytes,
  });

  ExportResult copyWith({
    String? id,
    ExportOptions? options,
    ExportStatus? status,
    String? filePath,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
    int? fileSizeBytes,
  }) {
    return ExportResult(
      id: id ?? this.id,
      options: options ?? this.options,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }

  String get fileSizeDisplay {
    if (fileSizeBytes == null) return 'Unknown';
    if (fileSizeBytes! < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes! < 1024 * 1024) {
      return '${(fileSizeBytes! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'options': options.toJson(),
      'status': status.toString(),
      'filePath': filePath,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'fileSizeBytes': fileSizeBytes,
    };
  }

  factory ExportResult.fromJson(Map<String, dynamic> json) {
    return ExportResult(
      id: json['id'] as String,
      options: ExportOptions.fromJson(json['options'] as Map<String, dynamic>),
      status: ExportStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ExportStatus.pending,
      ),
      filePath: json['filePath'] as String?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      fileSizeBytes: json['fileSizeBytes'] as int?,
    );
  }
}