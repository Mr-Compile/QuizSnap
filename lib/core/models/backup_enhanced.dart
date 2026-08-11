import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

// Enhanced backup models with file operations and integrity checks

class BackupFileModel {
  final String fileName;
  final String filePath;
  final int fileSizeBytes;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final BackupMetadata metadata;

  BackupFileModel({
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.createdAt,
    this.modifiedAt,
    required this.metadata,
  });

  String get fileSizeDisplay {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get displayName {
    final nameWithoutExt = fileName.replaceAll('.quizsnap', '').replaceAll('.json', '');
    return nameWithoutExt;
  }

  bool get isValidQuizSnapFile {
    return fileName.endsWith('.quizsnap') || fileName.endsWith('.json');
  }

  factory BackupFileModel.fromFile(File file, BackupMetadata metadata) {
    final stat = file.statSync();
    return BackupFileModel(
      fileName: file.path.split(Platform.pathSeparator).last,
      filePath: file.path,
      fileSizeBytes: stat.size,
      createdAt: stat.modified,
      modifiedAt: stat.modified,
      metadata: metadata,
    );
  }
}

class BackupIntegrityCheck {
  final bool isValid;
  final String? errorMessage;
  final String? checksum;
  final int version;
  final DateTime? backupDate;

  BackupIntegrityCheck({
    required this.isValid,
    this.errorMessage,
    this.checksum,
    required this.version,
    this.backupDate,
  });

  factory BackupIntegrityCheck.valid({
    required String checksum,
    required int version,
    DateTime? backupDate,
  }) {
    return BackupIntegrityCheck(
      isValid: true,
      checksum: checksum,
      version: version,
      backupDate: backupDate,
    );
  }

  factory BackupIntegrityCheck.invalid(String errorMessage) {
    return BackupIntegrityCheck(
      isValid: false,
      errorMessage: errorMessage,
      version: 0,
    );
  }
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
  final int studySessionCount;
  final int quizResultCount;
  final String? filePath;

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
    this.studySessionCount = 0,
    this.quizResultCount = 0,
    this.filePath,
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
    int? studySessionCount,
    int? quizResultCount,
    String? filePath,
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
      studySessionCount: studySessionCount ?? this.studySessionCount,
      quizResultCount: quizResultCount ?? this.quizResultCount,
      filePath: filePath ?? this.filePath,
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
      case BackupType.safety:
        return 'Safety';
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

  String get defaultFileName {
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(createdAt);
    return 'backup_$timestamp.quizsnap';
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
      'studySessionCount': studySessionCount,
      'quizResultCount': quizResultCount,
      'filePath': filePath,
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
      studySessionCount: json['studySessionCount'] as int? ?? 0,
      quizResultCount: json['quizResultCount'] as int? ?? 0,
      filePath: json['filePath'] as String?,
    );
  }
}

enum BackupType {
  manual,
  automatic,
  safety,
}

enum BackupStatus {
  pending,
  creating,
  completed,
  failed,
  restoring,
}

class BackupData {
  final int version;
  final String? checksum;
  final BackupMetadata metadata;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? appPreferences;

  BackupData({
    required this.version,
    this.checksum,
    required this.metadata,
    required this.data,
    this.appPreferences,
  });

  String generateChecksum() {
    final dataWithoutChecksum = {
      'version': version,
      'metadata': metadata.toJson(),
      'data': data,
      'appPreferences': appPreferences,
    };
    final jsonString = json.encode(dataWithoutChecksum);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verifyChecksum() {
    if (checksum == null) return false;
    return generateChecksum() == checksum;
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'checksum': checksum ?? generateChecksum(),
      'metadata': metadata.toJson(),
      'data': data,
      'appPreferences': appPreferences,
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as int,
      checksum: json['checksum'] as String?,
      metadata: BackupMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      data: json['data'] as Map<String, dynamic>,
      appPreferences: json['appPreferences'] as Map<String, dynamic>?,
    );
  }

  BackupData copyWith({
    int? version,
    String? checksum,
    BackupMetadata? metadata,
    Map<String, dynamic>? data,
    Map<String, dynamic>? appPreferences,
  }) {
    return BackupData(
      version: version ?? this.version,
      checksum: checksum ?? this.checksum,
      metadata: metadata ?? this.metadata,
      data: data ?? this.data,
      appPreferences: appPreferences ?? this.appPreferences,
    );
  }
}

class BackupSchedule {
  final bool enabled;
  final BackupFrequency frequency;
  final BackupRetention retention;
  final DateTime? lastBackupDate;
  final DateTime? nextBackupDate;
  final String? customBackupPath;

  BackupSchedule({
    required this.enabled,
    this.frequency = BackupFrequency.weekly,
    this.retention = BackupRetention.keep5,
    this.lastBackupDate,
    this.nextBackupDate,
    this.customBackupPath,
  });

  int get intervalDays {
    switch (frequency) {
      case BackupFrequency.daily:
        return 1;
      case BackupFrequency.weekly:
        return 7;
      case BackupFrequency.monthly:
        return 30;
    }
  }

  int get maxBackups {
    switch (retention) {
      case BackupRetention.keep3:
        return 3;
      case BackupRetention.keep5:
        return 5;
      case BackupRetention.keep10:
        return 10;
    }
  }

  String get frequencyDisplay {
    switch (frequency) {
      case BackupFrequency.daily:
        return 'Daily';
      case BackupFrequency.weekly:
        return 'Weekly';
      case BackupFrequency.monthly:
        return 'Monthly';
    }
  }

  String get retentionDisplay {
    switch (retention) {
      case BackupRetention.keep3:
        return 'Keep 3 backups';
      case BackupRetention.keep5:
        return 'Keep 5 backups';
      case BackupRetention.keep10:
        return 'Keep 10 backups';
    }
  }

  BackupSchedule copyWith({
    bool? enabled,
    BackupFrequency? frequency,
    BackupRetention? retention,
    DateTime? lastBackupDate,
    DateTime? nextBackupDate,
    String? customBackupPath,
  }) {
    return BackupSchedule(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      retention: retention ?? this.retention,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      nextBackupDate: nextBackupDate ?? this.nextBackupDate,
      customBackupPath: customBackupPath ?? this.customBackupPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'frequency': frequency.toString(),
      'retention': retention.toString(),
      'lastBackupDate': lastBackupDate?.toIso8601String(),
      'nextBackupDate': nextBackupDate?.toIso8601String(),
      'customBackupPath': customBackupPath,
    };
  }

  factory BackupSchedule.fromJson(Map<String, dynamic> json) {
    return BackupSchedule(
      enabled: json['enabled'] as bool,
      frequency: BackupFrequency.values.firstWhere(
        (e) => e.toString() == json['frequency'],
        orElse: () => BackupFrequency.weekly,
      ),
      retention: BackupRetention.values.firstWhere(
        (e) => e.toString() == json['retention'],
        orElse: () => BackupRetention.keep5,
      ),
      lastBackupDate: json['lastBackupDate'] != null
          ? DateTime.parse(json['lastBackupDate'] as String)
          : null,
      nextBackupDate: json['nextBackupDate'] != null
          ? DateTime.parse(json['nextBackupDate'] as String)
          : null,
      customBackupPath: json['customBackupPath'] as String?,
    );
  }
}

enum BackupFrequency {
  daily,
  weekly,
  monthly,
}

enum BackupRetention {
  keep3,
  keep5,
  keep10,
}

class RestoreOptions {
  final RestoreMode mode;
  final bool createSafetyBackup;
  final bool includeExtractedDocuments;
  final bool validateBeforeRestore;

  RestoreOptions({
    this.mode = RestoreMode.merge,
    this.createSafetyBackup = true,
    this.includeExtractedDocuments = false,
    this.validateBeforeRestore = true,
  });

  RestoreOptions copyWith({
    RestoreMode? mode,
    bool? createSafetyBackup,
    bool? includeExtractedDocuments,
    bool? validateBeforeRestore,
  }) {
    return RestoreOptions(
      mode: mode ?? this.mode,
      createSafetyBackup: createSafetyBackup ?? this.createSafetyBackup,
      includeExtractedDocuments: includeExtractedDocuments ?? this.includeExtractedDocuments,
      validateBeforeRestore: validateBeforeRestore ?? this.validateBeforeRestore,
    );
  }
}

enum RestoreMode {
  merge,
  replace,
}
