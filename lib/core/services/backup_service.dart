import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../models/backup.dart';
import '../repositories/deck_repository.dart';
import '../repositories/flashcard_repository.dart';
import '../repositories/folder_repository.dart';
import '../repositories/tag_repository.dart';

class BackupService {
  final AppDatabase _database;
  final DeckRepository _deckRepository;
  final FlashcardRepository _flashcardRepository;
  final FolderRepository _folderRepository;
  final TagRepository _tagRepository;
  static const String _backupScheduleKey = 'backup_schedule';
  static const String _backupHistoryKey = 'backup_history';

  BackupService(
    this._database,
    this._deckRepository,
    this._flashcardRepository,
    this._folderRepository,
    this._tagRepository,
  );

  // Create a manual backup
  Future<BackupMetadata> createBackup({
    String? name,
    String? description,
  }) async {
    final backupId = DateTime.now().millisecondsSinceEpoch.toString();
    final backupName = name ?? 'Backup_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}';
    
    final metadata = BackupMetadata(
      id: backupId,
      type: BackupType.manual,
      status: BackupStatus.creating,
      name: backupName,
      description: description,
      version: 1,
      createdAt: DateTime.now(),
      deckCount: 0,
      flashcardCount: 0,
      folderCount: 0,
      tagCount: 0,
    );

    try {
      // Get all data
      final folders = await _folderRepository.getAllFolders();
      final decks = await _deckRepository.getAllDecks();
      final flashcards = await _flashcardRepository.getAllFlashcards();
      final tags = await _database.getAllTags();
      final flashcardTags = await _database.getAllFlashcardTags();
      final studySessions = await _database.getAllStudySessions();
      final quizResults = await _database.getAllQuizResults();

      // Update metadata counts
      final updatedMetadata = metadata.copyWith(
        deckCount: decks.length,
        flashcardCount: flashcards.length,
        folderCount: folders.length,
        tagCount: tags.length,
      );

      // Create backup data
      final backupData = BackupData(
        metadata: updatedMetadata,
        folders: folders.map((f) => _folderToJson(f)).toList(),
        decks: decks.map((d) => _deckToJson(d)).toList(),
        flashcards: flashcards.map((f) => _flashcardToJson(f)).toList(),
        tags: tags.map((t) => _tagToJson(t)).toList(),
        flashcardTags: flashcardTags.map((ft) => _flashcardTagToJson(ft)).toList(),
        studySessions: studySessions.map((s) => _studySessionToJson(s)).toList(),
        quizResults: quizResults.map((q) => _quizResultToJson(q)).toList(),
      );

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final fileName = '$backupName.json';
      final filePath = '${backupDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(backupData.toJson()));

      final fileSize = await file.length();

      // Save to history
      await _addToBackupHistory(updatedMetadata.copyWith(
        status: BackupStatus.completed,
        completedAt: DateTime.now(),
        fileSizeBytes: fileSize,
      ));

      return updatedMetadata.copyWith(
        status: BackupStatus.completed,
        completedAt: DateTime.now(),
        fileSizeBytes: fileSize,
      );
    } catch (e) {
      final failedMetadata = metadata.copyWith(
        status: BackupStatus.failed,
        completedAt: DateTime.now(),
      );
      await _addToBackupHistory(failedMetadata);
      rethrow;
    }
  }

  // Restore from backup
  Future<BackupMetadata> restoreBackup(String backupId) async {
    final history = await getBackupHistory();
    final backupMetadata = history.firstWhere(
      (b) => b.id == backupId,
      orElse: () => throw Exception('Backup not found'),
    );

    try {
      // Update status to restoring
      final updatingMetadata = backupMetadata.copyWith(
        status: BackupStatus.restoring,
      );
      await _updateBackupInHistory(updatingMetadata);

      // Load backup file
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      final file = File('${backupDir.path}/${backupMetadata.name}.json');
      
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final backupData = BackupData.fromJson(jsonData);

      // Clear existing data (optional - could be made configurable)
      // await _clearAllData();

      // Restore folders
      for (final folderJson in backupData.folders) {
        final folder = Folder.fromJson(folderJson);
        await _database.createFolder(FoldersCompanion(
          name: Value(folder.name),
          description: Value(folder.description),
          color: Value(folder.color),
          createdAt: Value(folder.createdAt),
          updatedAt: Value(folder.updatedAt),
          deletedAt: Value(folder.deletedAt),
        ));
      }

      // Restore tags
      for (final tagJson in backupData.tags) {
        final tag = Tag.fromJson(tagJson);
        await _database.createTag(TagsCompanion(
          name: Value(tag.name),
          color: Value(tag.color),
          createdAt: Value(tag.createdAt),
          updatedAt: Value(tag.updatedAt),
        ));
      }

      // Restore decks
      final deckIdMap = <int, int>{}; // Map old IDs to new IDs
      for (final deckJson in backupData.decks) {
        final deck = Deck.fromJson(deckJson);
        final newId = await _database.createDeck(DecksCompanion(
          name: Value(deck.name),
          description: Value(deck.description),
          folderId: Value(deck.folderId),
          color: Value(deck.color),
          cardCount: Value(deck.cardCount),
          createdAt: Value(deck.createdAt),
          updatedAt: Value(deck.updatedAt),
          deletedAt: Value(deck.deletedAt),
        ));
        deckIdMap[deck.id] = newId;
      }

      // Restore flashcards
      final flashcardIdMap = <int, int>{};
      for (final flashcardJson in backupData.flashcards) {
        final flashcard = Flashcard.fromJson(flashcardJson);
        final oldDeckId = flashcard.deckId;
        final newDeckId = deckIdMap[oldDeckId] ?? oldDeckId;
        
        final newId = await _database.createFlashcard(FlashcardsCompanion(
          question: Value(flashcard.question),
          answer: Value(flashcard.answer),
          deckId: Value(newDeckId),
          order: Value(flashcard.order),
          isFavorite: Value(flashcard.isFavorite),
          reviewCount: Value(flashcard.reviewCount),
          correctCount: Value(flashcard.correctCount),
          lastReviewedAt: Value(flashcard.lastReviewedAt),
          nextReviewAt: Value(flashcard.nextReviewAt),
          easeFactor: Value(flashcard.easeFactor),
          interval: Value(flashcard.interval),
          repetitions: Value(flashcard.repetitions),
          createdAt: Value(flashcard.createdAt),
          updatedAt: Value(flashcard.updatedAt),
          deletedAt: Value(flashcard.deletedAt),
        ));
        flashcardIdMap[flashcard.id] = newId;
      }

      // Restore flashcard tags
      for (final flashcardTagJson in backupData.flashcardTags) {
        final flashcardTag = FlashcardTag.fromJson(flashcardTagJson);
        final oldFlashcardId = flashcardTag.flashcardId;
        final newFlashcardId = flashcardIdMap[oldFlashcardId] ?? oldFlashcardId;
        
        await _database.createFlashcardTag(FlashcardTagsCompanion(
          flashcardId: Value(newFlashcardId),
          tagId: Value(flashcardTag.tagId),
        ));
      }

      // Restore study sessions
      for (final sessionJson in backupData.studySessions) {
        final session = StudySession.fromJson(sessionJson);
        final oldDeckId = session.deckId;
        final newDeckId = deckIdMap[oldDeckId] ?? oldDeckId;
        
        await _database.createStudySession(StudySessionsCompanion(
          deckId: Value(newDeckId),
          cardsStudied: Value(session.cardsStudied),
          cardsCorrect: Value(session.cardsCorrect),
          durationSeconds: Value(session.durationSeconds),
          studyMode: Value(session.studyMode),
          startedAt: Value(session.startedAt),
          endedAt: Value(session.endedAt),
          createdAt: Value(session.createdAt),
        ));
      }

      // Restore quiz results
      for (final quizResultJson in backupData.quizResults) {
        final quizResult = QuizResult.fromJson(quizResultJson);
        final oldDeckId = quizResult.deckId;
        final newDeckId = deckIdMap[oldDeckId] ?? oldDeckId;
        
        await _database.createQuizResult(QuizResultsCompanion(
          deckId: Value(newDeckId),
          totalQuestions: Value(quizResult.totalQuestions),
          correctAnswers: Value(quizResult.correctAnswers),
          score: Value(quizResult.score),
          durationSeconds: Value(quizResult.durationSeconds),
          quizType: Value(quizResult.quizType),
          completedAt: Value(quizResult.completedAt),
          createdAt: Value(quizResult.createdAt),
        ));
      }

      // Update status to completed
      final completedMetadata = backupMetadata.copyWith(
        status: BackupStatus.completed,
      );
      await _updateBackupInHistory(completedMetadata);

      return completedMetadata;
    } catch (e) {
      final failedMetadata = backupMetadata.copyWith(
        status: BackupStatus.failed,
      );
      await _updateBackupInHistory(failedMetadata);
      rethrow;
    }
  }

  // Get backup history
  Future<List<BackupMetadata>> getBackupHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_backupHistoryKey);
    
    if (historyJson == null) return [];
    
    final List<dynamic> decoded = json.decode(historyJson);
    return decoded.map((e) => BackupMetadata.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Delete backup
  Future<void> deleteBackup(String backupId) async {
    final history = await getBackupHistory();
    final backup = history.firstWhere(
      (b) => b.id == backupId,
      orElse: () => throw Exception('Backup not found'),
    );

    // Delete file
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');
    final file = File('${backupDir.path}/${backup.name}.json');
    
    if (await file.exists()) {
      await file.delete();
    }

    // Remove from history
    final updatedHistory = history.where((b) => b.id != backupId).toList();
    await _saveBackupHistory(updatedHistory);
  }

  // Get backup schedule
  Future<BackupSchedule> getBackupSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final scheduleJson = prefs.getString(_backupScheduleKey);
    
    if (scheduleJson == null) {
      return BackupSchedule(
        enabled: false,
        intervalDays: 7, // Default to weekly
      );
    }
    
    return BackupSchedule.fromJson(json.decode(scheduleJson) as Map<String, dynamic>);
  }

  // Update backup schedule
  Future<void> updateBackupSchedule(BackupSchedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupScheduleKey, json.encode(schedule.toJson()));
  }

  // Check if automatic backup is due
  Future<bool> isAutomaticBackupDue() async {
    final schedule = await getBackupSchedule();
    
    if (!schedule.enabled) return false;
    if (schedule.nextBackupDate == null) return true;
    
    return DateTime.now().isAfter(schedule.nextBackupDate!);
  }

  // Perform automatic backup
  Future<BackupMetadata> performAutomaticBackup() async {
    final schedule = await getBackupSchedule();
    
    if (!schedule.enabled) {
      throw Exception('Automatic backup is not enabled');
    }

    final backup = await createBackup(
      name: 'Auto_Backup_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}',
      description: 'Automatic backup',
    );

    // Update schedule
    final nextBackupDate = DateTime.now().add(Duration(days: schedule.intervalDays));
    await updateBackupSchedule(schedule.copyWith(
      lastBackupDate: DateTime.now(),
      nextBackupDate: nextBackupDate,
    ));

    return backup.copyWith(type: BackupType.automatic);
  }

  // Helper methods
  Future<void> _addToBackupHistory(BackupMetadata metadata) async {
    final history = await getBackupHistory();
    history.add(metadata);
    await _saveBackupHistory(history);
  }

  Future<void> _updateBackupInHistory(BackupMetadata metadata) async {
    final history = await getBackupHistory();
    final index = history.indexWhere((b) => b.id == metadata.id);
    
    if (index != -1) {
      history[index] = metadata;
      await _saveBackupHistory(history);
    }
  }

  Future<void> _saveBackupHistory(List<BackupMetadata> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = json.encode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_backupHistoryKey, historyJson);
  }

  // JSON conversion helpers
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

  Future<void> _clearAllData() async {
    // Delete in reverse order of dependencies
    await _database.deleteAllQuizResults();
    await _database.deleteAllStudySessions();
    await _database.deleteAllFlashcardTags();
    await _database.deleteAllFlashcards();
    await _database.deleteAllDecks();
    await _database.deleteAllTags();
    await _database.deleteAllFolders();
  }
}