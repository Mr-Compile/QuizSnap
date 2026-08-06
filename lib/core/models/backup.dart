enum BackupType {
  manual,
  automatic,
}

enum BackupStatus {
  pending,
  creating,
  completed,
  failed,
  restoring,
}

class BackupMetadata {
  final String id;
  final BackupType type;
  final BackupStatus status;
  final String name;
  final String? description;
  final int version;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? fileSizeBytes;
  final int deckCount;
  final int flashcardCount;
  final int folderCount;
  final int tagCount;

  BackupMetadata({
    required this.id,
    required this.type,
    required this.status,
    required this.name,
    this.description,
    required this.version,
    required this.createdAt,
    this.completedAt,
    this.fileSizeBytes,
    required this.deckCount,
    required this.flashcardCount,
    required this.folderCount,
    required this.tagCount,
  });

  BackupMetadata copyWith({
    String? id,
    BackupType? type,
    BackupStatus? status,
    String? name,
    String? description,
    int? version,
    DateTime? createdAt,
    DateTime? completedAt,
    int? fileSizeBytes,
    int? deckCount,
    int? flashcardCount,
    int? folderCount,
    int? tagCount,
  }) {
    return BackupMetadata(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      deckCount: deckCount ?? this.deckCount,
      flashcardCount: flashcardCount ?? this.flashcardCount,
      folderCount: folderCount ?? this.folderCount,
      tagCount: tagCount ?? this.tagCount,
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

  String get typeDisplay {
    switch (type) {
      case BackupType.manual:
        return 'Manual';
      case BackupType.automatic:
        return 'Auto';
    }
  }

  String get statusDisplay {
    switch (status) {
      case BackupStatus.pending:
        return 'Pending';
      case BackupStatus.creating:
        return 'Creating';
      case BackupStatus.completed:
        return 'Completed';
      case BackupStatus.failed:
        return 'Failed';
      case BackupStatus.restoring:
        return 'Restoring';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'status': status.toString(),
      'name': name,
      'description': description,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'fileSizeBytes': fileSizeBytes,
      'deckCount': deckCount,
      'flashcardCount': flashcardCount,
      'folderCount': folderCount,
      'tagCount': tagCount,
    };
  }

  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      id: json['id'] as String,
      type: BackupType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => BackupType.manual,
      ),
      status: BackupStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => BackupStatus.pending,
      ),
      name: json['name'] as String,
      description: json['description'] as String?,
      version: json['version'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      fileSizeBytes: json['fileSizeBytes'] as int?,
      deckCount: json['deckCount'] as int,
      flashcardCount: json['flashcardCount'] as int,
      folderCount: json['folderCount'] as int,
      tagCount: json['tagCount'] as int,
    );
  }
}

class BackupData {
  final BackupMetadata metadata;
  final List<Map<String, dynamic>> folders;
  final List<Map<String, dynamic>> decks;
  final List<Map<String, dynamic>> flashcards;
  final List<Map<String, dynamic>> tags;
  final List<Map<String, dynamic>> flashcardTags;
  final List<Map<String, dynamic>> studySessions;
  final List<Map<String, dynamic>> quizResults;

  BackupData({
    required this.metadata,
    required this.folders,
    required this.decks,
    required this.flashcards,
    required this.tags,
    required this.flashcardTags,
    required this.studySessions,
    required this.quizResults,
  });

  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata.toJson(),
      'folders': folders,
      'decks': decks,
      'flashcards': flashcards,
      'tags': tags,
      'flashcardTags': flashcardTags,
      'studySessions': studySessions,
      'quizResults': quizResults,
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      metadata: BackupMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      folders: List<Map<String, dynamic>>.from(json['folders'] as List),
      decks: List<Map<String, dynamic>>.from(json['decks'] as List),
      flashcards: List<Map<String, dynamic>>.from(json['flashcards'] as List),
      tags: List<Map<String, dynamic>>.from(json['tags'] as List),
      flashcardTags: List<Map<String, dynamic>>.from(json['flashcardTags'] as List),
      studySessions: List<Map<String, dynamic>>.from(json['studySessions'] as List),
      quizResults: List<Map<String, dynamic>>.from(json['quizResults'] as List),
    );
  }
}

class BackupSchedule {
  final bool enabled;
  final int intervalDays; // e.g., 7 for weekly
  final DateTime? lastBackupDate;
  final DateTime? nextBackupDate;

  BackupSchedule({
    required this.enabled,
    required this.intervalDays,
    this.lastBackupDate,
    this.nextBackupDate,
  });

  BackupSchedule copyWith({
    bool? enabled,
    int? intervalDays,
    DateTime? lastBackupDate,
    DateTime? nextBackupDate,
  }) {
    return BackupSchedule(
      enabled: enabled ?? this.enabled,
      intervalDays: intervalDays ?? this.intervalDays,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      nextBackupDate: nextBackupDate ?? this.nextBackupDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'intervalDays': intervalDays,
      'lastBackupDate': lastBackupDate?.toIso8601String(),
      'nextBackupDate': nextBackupDate?.toIso8601String(),
    };
  }

  factory BackupSchedule.fromJson(Map<String, dynamic> json) {
    return BackupSchedule(
      enabled: json['enabled'] as bool,
      intervalDays: json['intervalDays'] as int,
      lastBackupDate: json['lastBackupDate'] != null
          ? DateTime.parse(json['lastBackupDate'] as String)
          : null,
      nextBackupDate: json['nextBackupDate'] != null
          ? DateTime.parse(json['nextBackupDate'] as String)
          : null,
    );
  }
}