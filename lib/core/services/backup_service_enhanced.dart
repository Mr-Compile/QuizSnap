import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/database.dart';
import '../models/backup_enhanced.dart';

class BackupServiceEnhanced {
  final AppDatabase _database;
  static const String _backupScheduleKey = 'backup_schedule_enhanced';
  static const String _backupHistoryKey = 'backup_history_enhanced';
  static const String _customBackupPathKey = 'custom_backup_path';

  BackupServiceEnhanced(this._database);

  // Export backup with file picker
  Future<BackupFileModel> exportBackup({
    String? name,
    String? description,
    String? customPath,
  }) async {
    final backupId = DateTime.now().millisecondsSinceEpoch.toString();
    final backupName = name ?? 'Backup_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}';
    
    final metadata = BackupMetadata(
      id: backupId,
      type: BackupType.manual,
      status: BackupStatus.creating,
      name: backupName,
      description: description,
      version: 2,
      createdAt: DateTime.now(),
      deckCount: 0,
      flashcardCount: 0,
      folderCount: 0,
      tagCount: 0,
    );

    try {
      // Get all data
      final folders = await _database.getAllFolders();
      final decks = await _database.getAllDecks();
      final flashcards = await _database.getAllFlashcards();
      final tags = await _database.getAllTags();
      final flashcardTags = await _database.getAllFlashcardTags();
      final studySessions = await _database.getAllStudySessions();
      final quizResults = await _database.getAllQuizResults();
      final aiUsage = await _getAllAiUsage();
      final extractedDocs = await _getAllExtractedDocuments();

      // Update metadata counts
      final updatedMetadata = metadata.copyWith(
        deckCount: decks.length,
        flashcardCount: flashcards.length,
        folderCount: folders.length,
        tagCount: tags.length,
        studySessionCount: studySessions.length,
        quizResultCount: quizResults.length,
      );

      // Create backup data
      final backupData = BackupData(
        version: 2,
        metadata: updatedMetadata,
        data: {
          'folders': folders.map((f) => _folderToJson(f)).toList(),
          'decks': decks.map((d) => _deckToJson(d)).toList(),
          'flashcards': flashcards.map((f) => _flashcardToJson(f)).toList(),
          'tags': tags.map((t) => _tagToJson(t)).toList(),
          'flashcardTags': flashcardTags.map((ft) => _flashcardTagToJson(ft)).toList(),
          'studySessions': studySessions.map((s) => _studySessionToJson(s)).toList(),
          'quizResults': quizResults.map((q) => _quizResultToJson(q)).toList(),
          'aiUsage': aiUsage.map((a) => _aiUsageToJson(a)).toList(),
          'extractedDocuments': extractedDocs.map((ed) => _extractedDocumentToJson(ed)).toList(),
        },
        appPreferences: await _getAppPreferences(),
      );

      // Generate checksum
      final checksum = backupData.generateChecksum();
      final finalBackupData = backupData.copyWith(checksum: checksum);

      // Determine save location
      String? savePath = customPath;
      if (savePath == null) {
        // Use file picker to let user choose location
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup',
          fileName: '$backupName.quizsnap',
          type: FileType.custom,
          allowedExtensions: ['quizsnap'],
          lockParentWindow: true,
        );

        if (result == null) {
          throw Exception('User cancelled save operation');
        }
        savePath = result;
      }

      // Ensure directory exists
      final directory = Directory(savePath).parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Save to file
      final file = File(savePath);
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(finalBackupData.toJson()));

      final fileSize = await file.length();

      // Update metadata with file info
      final finalMetadata = updatedMetadata.copyWith(
        status: BackupStatus.completed,
        completedAt: DateTime.now(),
        fileSizeBytes: fileSize,
        filePath: savePath,
      );

      // Save to history
      await _addToBackupHistory(finalMetadata);

      return BackupFileModel.fromFile(file, finalMetadata);
    } catch (e) {
      final failedMetadata = metadata.copyWith(
        status: BackupStatus.failed,
        completedAt: DateTime.now(),
      );
      await _addToBackupHistory(failedMetadata);
      rethrow;
    }
  }

  // Import backup from file
  Future<BackupData> importBackup(String filePath) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw Exception('Backup file not found');
    }

    final jsonString = await file.readAsString();
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    
    // Validate structure
    if (!jsonData.containsKey('version') || !jsonData.containsKey('metadata')) {
      throw Exception('Invalid backup file structure');
    }

    final backupData = BackupData.fromJson(jsonData);

    // Verify checksum if present
    if (backupData.checksum != null && !backupData.verifyChecksum()) {
      throw Exception('Backup file integrity check failed');
    }

    // Validate version compatibility
    if (backupData.version > 2) {
      throw Exception('Backup version ${backupData.version} is not supported');
    }

    return backupData;
  }

  // Get backup file info without importing
  Future<BackupMetadata> getBackupFileInfo(String filePath) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw Exception('Backup file not found');
    }

    final jsonString = await file.readAsString();
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    
    if (!jsonData.containsKey('metadata')) {
      throw Exception('Invalid backup file structure');
    }

    final metadata = BackupMetadata.fromJson(jsonData['metadata'] as Map<String, dynamic>);
    final stat = await file.stat();
    
    return metadata.copyWith(
      fileSizeBytes: stat.size,
      filePath: filePath,
    );
  }

  // Share backup file
  Future<void> shareBackup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found');
    }

    await share_plus.Share.shareXFiles([share_plus.XFile(filePath)], text: 'QuizSnap Backup');
  }

  // Open backup file location
  Future<void> openBackupLocation(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      // Try to open the file with OpenFilex
      final result = await OpenFilex.open(filePath);
      
      if (result.type != ResultType.done) {
        // If OpenFilex fails, try sharing as an alternative way to open
        await share_plus.Share.shareXFiles([share_plus.XFile(filePath)], text: 'QuizSnap Backup File');
      }
    } catch (e) {
      throw Exception('Failed to open file location: $e');
    }
  }

  // Open backup folder in file manager
  Future<void> openBackupFolder(String folderPath) async {
    try {
      final directory = Directory(folderPath);
      if (!await directory.exists()) {
        throw Exception('Folder does not exist');
      }

      // Try to open the folder using OpenFilex with a directory
      final result = await OpenFilex.open(folderPath);
      
      if (result.type != ResultType.done) {
        // If that fails, try opening a file in the directory as a workaround
        final files = directory.listSync().whereType<File>().toList();
        if (files.isNotEmpty) {
          await OpenFilex.open(files.first.path);
        } else {
          throw Exception('Could not open folder and no files found to use as workaround');
        }
      }
    } catch (e) {
      throw Exception('Failed to open folder: $e');
    }
  }

  // Copy backup file path to clipboard
  Future<void> copyBackupPath(String filePath) async {
    // This would need a clipboard package
    // For now, we'll return the path for the UI to handle
    throw UnimplementedError('Clipboard functionality requires additional package');
  }

  // Delete backup file
  Future<void> deleteBackupFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Get custom backup path
  Future<String?> getCustomBackupPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customBackupPathKey);
  }

  // Set custom backup path
  Future<void> setCustomBackupPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_customBackupPathKey);
    } else {
      await prefs.setString(_customBackupPathKey, path);
    }
  }

  // Request storage permission
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        // Show explanation dialog (handled by UI)
        return false;
      }
      if (status.isPermanentlyDenied) {
        // Guide to settings (handled by UI)
        return false;
      }
      return status.isGranted;
    }
    // iOS doesn't need explicit storage permission for app directory
    return true;
  }

  // Get default backup directory
  Future<Directory> getDefaultBackupDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/QuizSnap/Backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  // List backup files in directory
  Future<List<BackupFileModel>> listBackupFiles([String? directoryPath]) async {
    final directory = directoryPath != null 
        ? Directory(directoryPath)
        : await getDefaultBackupDirectory();
    
    if (!await directory.exists()) {
      return [];
    }

    final files = directory.listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.quizsnap') || f.path.endsWith('.json'))
        .toList();

    final backupFiles = <BackupFileModel>[];
    for (final file in files) {
      try {
        final metadata = await getBackupFileInfo(file.path);
        backupFiles.add(BackupFileModel.fromFile(file, metadata));
      } catch (e) {
        // Skip invalid files
        continue;
      }
    }

    return backupFiles..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Enhanced backup schedule methods
  Future<BackupSchedule> getBackupSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final scheduleJson = prefs.getString(_backupScheduleKey);
    final customPath = await getCustomBackupPath();
    
    if (scheduleJson == null) {
      return BackupSchedule(
        enabled: false,
        customBackupPath: customPath,
      );
    }
    
    final schedule = BackupSchedule.fromJson(json.decode(scheduleJson) as Map<String, dynamic>);
    return schedule.copyWith(customBackupPath: customPath);
  }

  Future<void> updateBackupSchedule(BackupSchedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupScheduleKey, json.encode(schedule.toJson()));
    if (schedule.customBackupPath != null) {
      await setCustomBackupPath(schedule.customBackupPath);
    }
  }

  Future<bool> isAutomaticBackupDue() async {
    final schedule = await getBackupSchedule();
    
    if (!schedule.enabled) return false;
    if (schedule.nextBackupDate == null) return true;
    
    return DateTime.now().isAfter(schedule.nextBackupDate!);
  }

  Future<BackupFileModel> performAutomaticBackup() async {
    final schedule = await getBackupSchedule();
    
    if (!schedule.enabled) {
      throw Exception('Automatic backup is not enabled');
    }

    // Clean up old backups based on retention policy
    await _cleanupOldBackups(schedule.maxBackups, schedule.customBackupPath);

    final backup = await exportBackup(
      name: 'Auto_Backup_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}',
      description: 'Automatic backup',
      customPath: schedule.customBackupPath,
    );

    // Update schedule
    final nextBackupDate = DateTime.now().add(Duration(days: schedule.intervalDays));
    await updateBackupSchedule(schedule.copyWith(
      lastBackupDate: DateTime.now(),
      nextBackupDate: nextBackupDate,
    ));

    return backup;
  }

  // Cleanup old backups based on retention policy
  Future<void> _cleanupOldBackups(int maxBackups, String? customPath) async {
    final backups = await listBackupFiles(customPath);
    
    if (backups.length <= maxBackups) return;

    // Keep only the most recent backups
    final backupsToDelete = backups.skip(maxBackups).toList();
    
    for (final backup in backupsToDelete) {
      try {
        await deleteBackupFile(backup.filePath);
        // Also remove from history
        await _removeFromBackupHistory(backup.metadata.id);
      } catch (e) {
        // Log error but continue
        continue;
      }
    }
  }

  // Backup history management
  Future<List<BackupMetadata>> getBackupHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_backupHistoryKey);
    
    if (historyJson == null) return [];
    
    final List<dynamic> decoded = json.decode(historyJson);
    return decoded.map((e) => BackupMetadata.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _addToBackupHistory(BackupMetadata metadata) async {
    final history = await getBackupHistory();
    history.add(metadata);
    await _saveBackupHistory(history);
  }

  Future<void> _removeFromBackupHistory(String backupId) async {
    final history = await getBackupHistory();
    final updatedHistory = history.where((b) => b.id != backupId).toList();
    await _saveBackupHistory(updatedHistory);
  }

  Future<void> _saveBackupHistory(List<BackupMetadata> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = json.encode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_backupHistoryKey, historyJson);
  }

  // Helper methods for data serialization
  Map<String, dynamic> _folderToJson(Folder folder) {
    return {
      'id': folder.id,
      'name': folder.name,
      'description': folder.description,
      'color': folder.color,
      'createdAt': folder.createdAt.toIso8601String(),
      'updatedAt': folder.updatedAt.toIso8601String(),
      'deletedAt': folder.deletedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> _deckToJson(Deck deck) {
    return {
      'id': deck.id,
      'name': deck.name,
      'description': deck.description,
      'folderId': deck.folderId,
      'color': deck.color,
      'cardCount': deck.cardCount,
      'createdAt': deck.createdAt.toIso8601String(),
      'updatedAt': deck.updatedAt.toIso8601String(),
      'deletedAt': deck.deletedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> _flashcardToJson(Flashcard flashcard) {
    return {
      'id': flashcard.id,
      'question': flashcard.question,
      'answer': flashcard.answer,
      'deckId': flashcard.deckId,
      'order': flashcard.order,
      'isFavorite': flashcard.isFavorite,
      'reviewCount': flashcard.reviewCount,
      'correctCount': flashcard.correctCount,
      'lastReviewedAt': flashcard.lastReviewedAt?.toIso8601String(),
      'nextReviewAt': flashcard.nextReviewAt?.toIso8601String(),
      'easeFactor': flashcard.easeFactor,
      'interval': flashcard.interval,
      'repetitions': flashcard.repetitions,
      'createdAt': flashcard.createdAt.toIso8601String(),
      'updatedAt': flashcard.updatedAt.toIso8601String(),
      'deletedAt': flashcard.deletedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> _tagToJson(Tag tag) {
    return {
      'id': tag.id,
      'name': tag.name,
      'color': tag.color,
      'createdAt': tag.createdAt.toIso8601String(),
      'updatedAt': tag.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _flashcardTagToJson(FlashcardTag flashcardTag) {
    return {
      'flashcardId': flashcardTag.flashcardId,
      'tagId': flashcardTag.tagId,
    };
  }

  Map<String, dynamic> _studySessionToJson(StudySession session) {
    return {
      'id': session.id,
      'deckId': session.deckId,
      'cardsStudied': session.cardsStudied,
      'cardsCorrect': session.cardsCorrect,
      'durationSeconds': session.durationSeconds,
      'studyMode': session.studyMode,
      'startedAt': session.startedAt.toIso8601String(),
      'endedAt': session.endedAt?.toIso8601String(),
      'createdAt': session.createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _quizResultToJson(QuizResult quizResult) {
    return {
      'id': quizResult.id,
      'deckId': quizResult.deckId,
      'totalQuestions': quizResult.totalQuestions,
      'correctAnswers': quizResult.correctAnswers,
      'score': quizResult.score,
      'durationSeconds': quizResult.durationSeconds,
      'quizType': quizResult.quizType,
      'completedAt': quizResult.completedAt.toIso8601String(),
      'createdAt': quizResult.createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _aiUsageToJson(AiUsageData aiUsage) {
    return {
      'id': aiUsage.id,
      'date': aiUsage.date,
      'usedCount': aiUsage.usedCount,
      'dailyLimit': aiUsage.dailyLimit,
      'lastResetAt': aiUsage.lastResetAt.toIso8601String(),
      'createdAt': aiUsage.createdAt.toIso8601String(),
      'updatedAt': aiUsage.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _extractedDocumentToJson(ExtractedDocument doc) {
    return {
      'id': doc.id,
      'fileName': doc.fileName,
      'filePath': doc.filePath,
      'extractedText': doc.extractedText,
      'selectedScope': doc.selectedScope,
      'scopeDetails': doc.scopeDetails,
      'totalPages': doc.totalPages,
      'characterCount': doc.characterCount,
      'createdAt': doc.createdAt.toIso8601String(),
      'lastUsedAt': doc.lastUsedAt?.toIso8601String(),
    };
  }

  Future<List<AiUsageData>> _getAllAiUsage() async {
    return await _database.getAllAiUsage();
  }

  Future<List<ExtractedDocument>> _getAllExtractedDocuments() async {
    return await _database.getAllExtractedDocuments();
  }

  Future<Map<String, dynamic>?> _getAppPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'theme': prefs.getString('theme') ?? 'system',
      'language': prefs.getString('language') ?? 'en',
      'backupSettings': prefs.getString(_backupScheduleKey),
    };
  }
}
