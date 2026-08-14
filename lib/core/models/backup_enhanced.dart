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
    final nameWithoutExt = fileName
        .replaceAll('.db', '')
        .replaceAll('.quizsnap', '')
        .replaceAll('.json', '');
    return nameWithoutExt;
  }

  bool get isValidQuizSnapFile {
    return fileName.endsWith('.db') ||
        fileName.endsWith('.quizsnap') ||
        fileName.endsWith('.json');
  }

  bool get isDbBackup => fileName.endsWith('.db');

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

  /// Build a [BackupFileModel] for a real SQLite `.db` backup file when no JSON
  /// metadata is available. Metadata counts are unknown for raw db files and
  /// default to zero.
  factory BackupFileModel.fromDbFile(File file) {
    final stat = file.statSync();
    final name = file.path.split(Platform.pathSeparator).last;
    return BackupFileModel(
      fileName: name,
      filePath: file.path,
      fileSizeBytes: stat.size,
      createdAt: stat.modified,
      modifiedAt: stat.modified,
      metadata: BackupMetadata(
        id: name,
        type: BackupType.manual,
        status: BackupStatus.completed,
        name: name,
        version: 2,
        createdAt: stat.modified,
        completedAt: stat.modified,
        fileSizeBytes: stat.size,
        deckCount: 0,
        flashcardCount: 0,
        folderCount: 0,
        tagCount: 0,
        filePath: file.path,
      ),
    );
  }

  /// Build a [BackupFileModel] from a SAF file listing entry (name/size/date).
  factory BackupFileModel.fromSafEntry({
    required String name,
    required int size,
    required int lastModified,
    required String treeUri,
  }) {
    final modified = DateTime.fromMillisecondsSinceEpoch(lastModified);
    return BackupFileModel(
      fileName: name,
      // For SAF files we store the treeUri as filePath; the service resolves
      // the actual file via the native bridge when needed.
      filePath: '$treeUri/$name',
      fileSizeBytes: size,
      createdAt: modified,
      modifiedAt: modified,
      metadata: BackupMetadata(
        id: name,
        type: BackupType.manual,
        status: BackupStatus.completed,
        name: name,
        version: 2,
        createdAt: modified,
        completedAt: modified,
        fileSizeBytes: size,
        deckCount: 0,
        flashcardCount: 0,
        folderCount: 0,
        tagCount: 0,
        filePath: '$treeUri/$name',
      ),
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

/// Aggregated, dynamic information about the active backup folder.
///
/// Built by [BackupServiceEnhanced.getBackupFolderInfo] and exposed to the UI
/// through [backupSettingsProvider] so the Backup & Restore screen reacts
/// immediately when the folder changes or files are added/removed.
class BackupFolderInfo {
  /// Full folder path (filesystem path or SAF tree URI).
  final String folderPath;

  /// Human-readable folder name (last path segment or SAF display name).
  final String folderName;

  /// `true` when using the default app-specific backup folder.
  final bool isUsingDefaultFolder;

  /// `true` when the folder is reachable and listable.
  final bool exists;

  /// `.db` backup files inside the folder, newest first.
  final List<BackupFileModel> backupFiles;

  /// Sum of all backup file sizes in bytes.
  final int totalSizeBytes;

  /// Set when listing failed for a reason other than the folder being missing.
  final String? readError;

  const BackupFolderInfo({
    required this.folderPath,
    required this.folderName,
    required this.isUsingDefaultFolder,
    required this.exists,
    required this.backupFiles,
    required this.totalSizeBytes,
    this.readError,
  });

  int get backupCount => backupFiles.length;

  BackupFileModel? get newestBackup =>
      backupFiles.isEmpty ? null : backupFiles.first;

  DateTime? get lastBackupDate => newestBackup?.createdAt;

  String get totalSizeDisplay => _formatBytes(totalSizeBytes);

  String get storageTypeLabel =>
      isUsingDefaultFolder ? 'Default' : 'Custom';
}

/// Live counts of the user's protected data, read from the database.
class DataProtectedSummary {
  final int deckCount;
  final int flashcardCount;
  final int bookmarkCount;
  final int studySessionCount;
  final int quizResultCount;

  const DataProtectedSummary({
    this.deckCount = 0,
    this.flashcardCount = 0,
    this.bookmarkCount = 0,
    this.studySessionCount = 0,
    this.quizResultCount = 0,
  });

  int get analyticsCount => studySessionCount + quizResultCount;
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
