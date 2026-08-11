import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../models/backup_enhanced.dart';
import 'backup_service_enhanced.dart';

class RestoreService {
  final AppDatabase _database;
  final BackupServiceEnhanced _backupService;

  RestoreService(this._database, this._backupService);

  // Restore from backup with options
  Future<RestoreResult> restoreBackup(
    BackupData backupData,
    RestoreOptions options,
  ) async {
    final safetyBackupId = DateTime.now().millisecondsSinceEpoch.toString();
    
    try {
      // Create safety backup if requested
      if (options.createSafetyBackup) {
        await _createSafetyBackup(safetyBackupId);
      }

      // Validate backup before restore if requested
      if (options.validateBeforeRestore) {
        final validation = _validateBackupData(backupData);
        if (!validation.isValid) {
          throw Exception('Backup validation failed: ${validation.errorMessage}');
        }
      }

      // Begin transaction
      return await _database.transaction(() async {
        try {
          if (options.mode == RestoreMode.replace) {
            await _clearAllData();
          }

          // Restore data
          final stats = await _restoreData(backupData, options);

          return RestoreResult(
            success: true,
            safetyBackupId: options.createSafetyBackup ? safetyBackupId : null,
            restoredStats: stats,
          );
        } catch (e) {
          // Rollback will happen automatically due to transaction
          throw RestoreException('Restore failed: $e', safetyBackupId);
        }
      });
    } catch (e) {
      if (e is RestoreException) {
        rethrow;
      }
      throw RestoreException('Restore failed: $e', safetyBackupId);
    }
  }

  // Create safety backup before restore
  Future<void> _createSafetyBackup(String backupId) async {
    try {
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      await _backupService.exportBackup(
        name: 'Safety_Backup_$timestamp',
        description: 'Automatic safety backup before restore',
      );
    } catch (e) {
      // Log warning but don't fail the restore
      debugPrint('Warning: Failed to create safety backup: $e');
    }
  }

  // Validate backup data structure
  BackupValidation _validateBackupData(BackupData backupData) {
    // Check version compatibility
    if (backupData.version > 2) {
      return BackupValidation.invalid('Backup version ${backupData.version} is not supported');
    }

    // Verify checksum
    if (backupData.checksum != null && !backupData.verifyChecksum()) {
      return BackupValidation.invalid('Backup file integrity check failed');
    }

    // Check required data sections
    final data = backupData.data;
    if (!data.containsKey('folders') || 
        !data.containsKey('decks') || 
        !data.containsKey('flashcards')) {
      return BackupValidation.invalid('Backup is missing required data sections');
    }

    // Validate data types
    if (data['folders'] is! List || 
        data['decks'] is! List || 
        data['flashcards'] is! List) {
      return BackupValidation.invalid('Backup data has invalid structure');
    }

    return BackupValidation.valid();
  }

  // Clear all data for replace mode
  Future<void> _clearAllData() async {
    // Delete in correct order to respect foreign key constraints
    await _database.deleteAllQuizResults();
    await _database.deleteAllStudySessions();
    await _database.deleteAllFlashcardTags();
    await _database.deleteAllFlashcards();
    await _database.deleteAllDecks();
    await _database.deleteAllTags();
    await _database.deleteAllFolders();
    await _database.deleteAllAiUsage();
    await _database.deleteAllExtractedDocuments();
  }

  // Restore data from backup
  Future<RestoreStats> _restoreData(BackupData backupData, RestoreOptions options) async {
    final data = backupData.data;
    final stats = RestoreStats();

    // Restore folders first (no dependencies)
    final foldersJson = data['folders'] as List;
    for (final folderJson in foldersJson) {
      try {
        final folder = Folder.fromJson(folderJson as Map<String, dynamic>);
        
        // Check if folder already exists (for merge mode)
        if (options.mode == RestoreMode.merge) {
          final existing = await (_database.select(_database.folders)
            ..where((f) => f.name.equals(folder.name))
            ..where((f) => f.deletedAt.isNull()))
            .get();
          
          if (existing.isNotEmpty) {
            stats.skippedFolders++;
            continue;
          }
        }

        await _database.createFolder(FoldersCompanion(
          name: Value(folder.name),
          description: Value(folder.description),
          color: Value(folder.color),
          createdAt: Value(folder.createdAt),
          updatedAt: Value(folder.updatedAt),
          deletedAt: Value(folder.deletedAt),
        ));
        stats.restoredFolders++;
      } catch (e) {
        stats.errors.add('Failed to restore folder: $e');
      }
    }

    // Restore tags (no dependencies)
    final tagsJson = data['tags'] as List;
    for (final tagJson in tagsJson) {
      try {
        final tag = Tag.fromJson(tagJson as Map<String, dynamic>);
        
        if (options.mode == RestoreMode.merge) {
          final existing = await (_database.select(_database.tags)
            ..where((t) => t.name.equals(tag.name)))
            .get();
          
          if (existing.isNotEmpty) {
            stats.skippedTags++;
            continue;
          }
        }

        await _database.createTag(TagsCompanion(
          name: Value(tag.name),
          color: Value(tag.color),
          createdAt: Value(tag.createdAt),
          updatedAt: Value(tag.updatedAt),
        ));
        stats.restoredTags++;
      } catch (e) {
        stats.errors.add('Failed to restore tag: $e');
      }
    }

    // Restore decks (depends on folders)
    final deckIdMap = <int, int>{};
    final decksJson = data['decks'] as List;
    for (final deckJson in decksJson) {
      try {
        final deck = Deck.fromJson(deckJson as Map<String, dynamic>);
        
        if (options.mode == RestoreMode.merge) {
          final existing = await (_database.select(_database.decks)
            ..where((d) => d.name.equals(deck.name))
            ..where((d) => d.deletedAt.isNull()))
            .get();
          
          if (existing.isNotEmpty) {
            stats.skippedDecks++;
            deckIdMap[deck.id] = existing.first.id;
            continue;
          }
        }

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
        stats.restoredDecks++;
      } catch (e) {
        stats.errors.add('Failed to restore deck: $e');
      }
    }

    // Restore flashcards (depends on decks)
    final flashcardIdMap = <int, int>{};
    final flashcardsJson = data['flashcards'] as List;
    for (final flashcardJson in flashcardsJson) {
      try {
        final flashcard = Flashcard.fromJson(flashcardJson as Map<String, dynamic>);
        final oldDeckId = flashcard.deckId;
        final newDeckId = deckIdMap[oldDeckId] ?? oldDeckId;
        
        if (options.mode == RestoreMode.merge) {
          // Check for duplicate flashcards in same deck
          final existing = await (_database.select(_database.flashcards)
            ..where((f) => f.deckId.equals(newDeckId))
            ..where((f) => f.question.equals(flashcard.question))
            ..where((f) => f.deletedAt.isNull()))
            .get();
          
          if (existing.isNotEmpty) {
            stats.skippedFlashcards++;
            flashcardIdMap[flashcard.id] = existing.first.id;
            continue;
          }
        }

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
        stats.restoredFlashcards++;
      } catch (e) {
        stats.errors.add('Failed to restore flashcard: $e');
      }
    }

    // Restore flashcard tags
    final flashcardTagsJson = data['flashcardTags'] as List;
    for (final flashcardTagJson in flashcardTagsJson) {
      try {
        final flashcardTag = FlashcardTag.fromJson(flashcardTagJson as Map<String, dynamic>);
        final oldFlashcardId = flashcardTag.flashcardId;
        final newFlashcardId = flashcardIdMap[oldFlashcardId] ?? oldFlashcardId;
        
        await _database.createFlashcardTag(FlashcardTagsCompanion(
          flashcardId: Value(newFlashcardId),
          tagId: Value(flashcardTag.tagId),
        ));
        stats.restoredFlashcardTags++;
      } catch (e) {
        stats.errors.add('Failed to restore flashcard tag: $e');
      }
    }

    // Restore study sessions
    final studySessionsJson = data['studySessions'] as List;
    for (final sessionJson in studySessionsJson) {
      try {
        final session = StudySession.fromJson(sessionJson as Map<String, dynamic>);
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
        stats.restoredStudySessions++;
      } catch (e) {
        stats.errors.add('Failed to restore study session: $e');
      }
    }

    // Restore quiz results
    final quizResultsJson = data['quizResults'] as List;
    for (final quizResultJson in quizResultsJson) {
      try {
        final quizResult = QuizResult.fromJson(quizResultJson as Map<String, dynamic>);
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
        stats.restoredQuizResults++;
      } catch (e) {
        stats.errors.add('Failed to restore quiz result: $e');
      }
    }

    // Restore AI usage if present
    if (data.containsKey('aiUsage')) {
      final aiUsageJson = data['aiUsage'] as List;
      for (final aiUsageJson in aiUsageJson) {
        try {
          final aiUsage = AiUsageData.fromJson(aiUsageJson as Map<String, dynamic>);
          await _database.createAiUsage(AiUsageCompanion(
            date: Value(aiUsage.date),
            usedCount: Value(aiUsage.usedCount),
            dailyLimit: Value(aiUsage.dailyLimit),
            lastResetAt: Value(aiUsage.lastResetAt),
            createdAt: Value(aiUsage.createdAt),
            updatedAt: Value(aiUsage.updatedAt),
          ));
          stats.restoredAiUsage++;
        } catch (e) {
          stats.errors.add('Failed to restore AI usage: $e');
        }
      }
    }

    // Restore extracted documents if requested and present
    if (options.includeExtractedDocuments && data.containsKey('extractedDocuments')) {
      final extractedDocsJson = data['extractedDocuments'] as List;
      for (final docJson in extractedDocsJson) {
        try {
          final doc = ExtractedDocument.fromJson(docJson as Map<String, dynamic>);
          await _database.createExtractedDocument(ExtractedDocumentsCompanion(
            fileName: Value(doc.fileName),
            filePath: Value(doc.filePath),
            extractedText: Value(doc.extractedText),
            selectedScope: Value(doc.selectedScope),
            scopeDetails: Value(doc.scopeDetails),
            totalPages: Value(doc.totalPages),
            characterCount: Value(doc.characterCount),
            createdAt: Value(doc.createdAt),
            lastUsedAt: Value(doc.lastUsedAt),
          ));
          stats.restoredExtractedDocuments++;
        } catch (e) {
          stats.errors.add('Failed to restore extracted document: $e');
        }
      }
    }

    // Restore app preferences if present
    if (backupData.appPreferences != null) {
      await _restoreAppPreferences(backupData.appPreferences!);
    }

    return stats;
  }

  // Restore app preferences
  Future<void> _restoreAppPreferences(Map<String, dynamic> preferences) async {
    // This would integrate with SharedPreferences
    // For now, we'll just restore theme and language
    // final prefs = await SharedPreferences.getInstance();
    // if (preferences.containsKey('theme')) {
    //   await prefs.setString('theme', preferences['theme'] as String);
    // }
    // if (preferences.containsKey('language')) {
    //   await prefs.setString('language', preferences['language'] as String);
    // }
  }

  // Rollback to safety backup
  Future<void> rollbackToSafetyBackup(String safetyBackupId) async {
    try {
      // Find the safety backup file
      final history = await _backupService.getBackupHistory();
      final safetyBackup = history.firstWhere(
        (b) => b.id == safetyBackupId && b.type == BackupType.safety,
        orElse: () => throw Exception('Safety backup not found'),
      );

      if (safetyBackup.filePath == null) {
        throw Exception('Safety backup file path not available');
      }

      // Import and restore the safety backup
      final backupData = await _backupService.importBackup(safetyBackup.filePath!);
      await restoreBackup(
        backupData,
        RestoreOptions(
          mode: RestoreMode.replace,
          createSafetyBackup: false,
          validateBeforeRestore: true,
        ),
      );
    } catch (e) {
      throw Exception('Rollback failed: $e');
    }
  }
}

// Result classes
class RestoreResult {
  final bool success;
  final String? safetyBackupId;
  final RestoreStats restoredStats;

  RestoreResult({
    required this.success,
    this.safetyBackupId,
    required this.restoredStats,
  });
}

class RestoreStats {
  int restoredFolders = 0;
  int restoredDecks = 0;
  int restoredFlashcards = 0;
  int restoredTags = 0;
  int restoredFlashcardTags = 0;
  int restoredStudySessions = 0;
  int restoredQuizResults = 0;
  int restoredAiUsage = 0;
  int restoredExtractedDocuments = 0;
  int skippedFolders = 0;
  int skippedDecks = 0;
  int skippedFlashcards = 0;
  int skippedTags = 0;
  final List<String> errors = [];

  int get totalRestored => restoredFolders + restoredDecks + restoredFlashcards + 
                          restoredTags + restoredFlashcardTags + restoredStudySessions + 
                          restoredQuizResults + restoredAiUsage + restoredExtractedDocuments;

  int get totalSkipped => skippedFolders + skippedDecks + skippedFlashcards + skippedTags;

  bool get hasErrors => errors.isNotEmpty;
}

class BackupValidation {
  final bool isValid;
  final String? errorMessage;

  BackupValidation.valid() : isValid = true, errorMessage = null;
  BackupValidation.invalid(this.errorMessage) : isValid = false;
}

class RestoreException implements Exception {
  final String message;
  final String? safetyBackupId;

  RestoreException(this.message, this.safetyBackupId);

  @override
  String toString() => message;
}
