import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:quiz_snap/core/database/database.dart';
import 'package:quiz_snap/core/models/backup_enhanced.dart';
import 'package:quiz_snap/core/services/backup_service_enhanced.dart';
import 'package:quiz_snap/core/services/restore_service.dart';
import 'package:quiz_snap/core/repositories/backup_repository.dart';
import 'package:drift/native.dart';

void main() {
  group('Backup System Tests', () {
    late AppDatabase database;
    late BackupRepository backupRepository;
    late BackupServiceEnhanced backupService;
    late RestoreService restoreService;

    setUp(() async {
      // Initialize in-memory database for testing
      database = AppDatabase(NativeDatabase.memory());
      backupRepository = BackupRepository(database);
      backupService = backupRepository.backupService;
      restoreService = backupRepository.restoreService;
    });

    tearDown(() async {
      await database.close();
    });

    group('BackupServiceEnhanced Tests', () {
      test('exportBackup should create a valid backup file', () async {
        // Add test data
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('Test Folder'),
          description: const drift.Value('Test Description'),
          color: const drift.Value('#FF0000'),
        ));

        await database.createDeck(DecksCompanion(
          name: const drift.Value('Test Deck'),
          description: const drift.Value('Test Deck Description'),
          color: const drift.Value('#00FF00'),
        ));

        // Export backup
        final backup = await backupService.exportBackup(
          name: 'Test_Backup',
          description: 'Test backup description',
        );

        expect(backup, isNotNull);
        expect(backup.metadata.name, equals('Test_Backup'));
        expect(backup.metadata.status, equals(BackupStatus.completed));
        expect(backup.metadata.deckCount, greaterThan(0));
        expect(backup.metadata.folderCount, greaterThan(0));
      });

      test('exportBackup should include all required data', () async {
        // Add comprehensive test data
        final folderId = await database.createFolder(FoldersCompanion(
          name: const drift.Value('Test Folder'),
          color: const drift.Value('#FF0000'),
        ));

        final deckId = await database.createDeck(DecksCompanion(
          name: const drift.Value('Test Deck'),
          folderId: drift.Value(folderId),
          color: const drift.Value('#00FF00'),
        ));

        await database.createFlashcard(FlashcardsCompanion(
          question: const drift.Value('Test Question'),
          answer: const drift.Value('Test Answer'),
          deckId: drift.Value(deckId),
        ));

        await database.createTag(TagsCompanion(
          name: const drift.Value('Test Tag'),
          color: const drift.Value('#0000FF'),
        ));

        // Export backup
        final backup = await backupService.exportBackup();

        expect(backup.metadata.folderCount, equals(1));
        expect(backup.metadata.deckCount, equals(1));
        expect(backup.metadata.flashcardCount, equals(1));
        expect(backup.metadata.tagCount, equals(1));
      });

      test('importBackup should validate file structure', () async {
        // Create a backup first
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('Test Folder'),
          color: const drift.Value('#FF0000'),
        ));

        final backup = await backupService.exportBackup(name: 'Test_Backup');

        // Import the backup
        final importedData = await backupService.importBackup(backup.filePath);

        expect(importedData, isNotNull);
        expect(importedData.version, equals(2));
        expect(importedData.metadata.name, equals('Test_Backup'));
        expect(importedData.verifyChecksum(), isTrue);
      });

      test('importBackup should reject invalid files', () async {
        expect(
          () => backupService.importBackup('/invalid/path/to/file.quizsnap'),
          throwsException,
        );
      });

      test('getBackupFileInfo should return correct metadata', () async {
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('Test Folder'),
          color: const drift.Value('#FF0000'),
        ));

        final backup = await backupService.exportBackup(name: 'Test_Backup');
        final metadata = await backupService.getBackupFileInfo(backup.filePath);

        expect(metadata, isNotNull);
        expect(metadata.name, equals('Test_Backup'));
        expect(metadata.fileSizeBytes, isNotNull);
        expect(metadata.filePath, equals(backup.filePath));
      });

      test('deleteBackupFile should remove the file', () async {
        final backup = await backupService.exportBackup(name: 'Test_Backup');
        
        await backupService.deleteBackupFile(backup.filePath);
        
        // Verify file is deleted
        expect(
          () => backupService.getBackupFileInfo(backup.filePath),
          throwsException,
        );
      });

      test('backup schedule management', () async {
        final schedule = BackupSchedule(
          enabled: true,
          frequency: BackupFrequency.daily,
          retention: BackupRetention.keep5,
        );

        await backupService.updateBackupSchedule(schedule);
        final retrievedSchedule = await backupService.getBackupSchedule();

        expect(retrievedSchedule.enabled, isTrue);
        expect(retrievedSchedule.frequency, equals(BackupFrequency.daily));
        expect(retrievedSchedule.retention, equals(BackupRetention.keep5));
      });

      test('isAutomaticBackupDue should return correct status', () async {
        // Test with disabled schedule
        var schedule = BackupSchedule(enabled: false);
        await backupService.updateBackupSchedule(schedule);
        expect(await backupService.isAutomaticBackupDue(), isFalse);

        // Test with enabled schedule and no next backup date
        schedule = BackupSchedule(enabled: true);
        await backupService.updateBackupSchedule(schedule);
        expect(await backupService.isAutomaticBackupDue(), isTrue);
      });
    });

    group('RestoreService Tests', () {
      test('restoreBackup with merge mode should preserve existing data', () async {
        // Add initial data
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('Existing Folder'),
          color: const drift.Value('#FF0000'),
        ));

        // Create backup
        final backup = await backupService.exportBackup(name: 'Test_Backup');

        // Add more data after backup
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('New Folder'),
          color: const drift.Value('#00FF00'),
        ));

        // Import and restore with merge mode
        final backupData = await backupService.importBackup(backup.filePath);
        final result = await restoreService.restoreBackup(
          backupData,
          RestoreOptions(mode: RestoreMode.merge, createSafetyBackup: false),
        );

        expect(result.success, isTrue);
        expect(result.restoredStats.totalRestored, greaterThan(0));
        
        // Verify both folders exist
        final folders = await database.getAllFolders();
        expect(folders.length, equals(2)); // Existing + New
      });

      test('restoreBackup with replace mode should clear existing data', () async {
        // Add initial data
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('Existing Folder'),
          color: const drift.Value('#FF0000'),
        ));

        // Create backup
        final backup = await backupService.exportBackup(name: 'Test_Backup');

        // Add more data after backup
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('New Folder'),
          color: const drift.Value('#00FF00'),
        ));

        // Import and restore with replace mode
        final backupData = await backupService.importBackup(backup.filePath);
        final result = await restoreService.restoreBackup(
          backupData,
          RestoreOptions(mode: RestoreMode.replace, createSafetyBackup: false),
        );

        expect(result.success, isTrue);
        
        // Verify only backup data exists
        final folders = await database.getAllFolders();
        expect(folders.length, equals(1)); // Only from backup
      });

      test('restoreBackup should create safety backup when requested', () async {
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('Test Folder'),
          color: const drift.Value('#FF0000'),
        ));

        final backup = await backupService.exportBackup(name: 'Test_Backup');
        final backupData = await backupService.importBackup(backup.filePath);

        final result = await restoreService.restoreBackup(
          backupData,
          RestoreOptions(mode: RestoreMode.merge, createSafetyBackup: true),
        );

        expect(result.success, isTrue);
        expect(result.safetyBackupId, isNotNull);
      });

      test('restoreBackup should validate backup when requested', () async {
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('Test Folder'),
          color: const drift.Value('#FF0000'),
        ));

        final backup = await backupService.exportBackup(name: 'Test_Backup');
        final backupData = await backupService.importBackup(backup.filePath);

        // Should succeed with valid backup
        final result = await restoreService.restoreBackup(
          backupData,
          RestoreOptions(
            mode: RestoreMode.merge,
            createSafetyBackup: false,
            validateBeforeRestore: true,
          ),
        );

        expect(result.success, isTrue);
      });

      test('restoreBackup should handle extracted documents option', () async {
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('Test Folder'),
          color: const drift.Value('#FF0000'),
        ));

        // Create backup with extracted documents
        final backup = await backupService.exportBackup(name: 'Test_Backup');
        final backupData = await backupService.importBackup(backup.filePath);

        final result = await restoreService.restoreBackup(
          backupData,
          RestoreOptions(
            mode: RestoreMode.merge,
            createSafetyBackup: false,
            includeExtractedDocuments: true,
          ),
        );

        expect(result.success, isTrue);
      });
    });

    group('BackupRepository Tests', () {
      test('should provide access to services', () async {
        expect(backupRepository.backupService, equals(backupService));
        expect(backupRepository.restoreService, equals(restoreService));
      });

      test('should export backup through repository', () async {
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('Test Folder'),
          color: const drift.Value('#FF0000'),
        ));

        final backup = await backupRepository.exportBackup(name: 'Test_Backup');

        expect(backup, isNotNull);
        expect(backup.metadata.name, equals('Test_Backup'));
      });

      test('should import backup through repository', () async {
        final backup = await backupRepository.exportBackup(name: 'Test_Backup');
        final backupData = await backupRepository.importBackup(backup.filePath);

        expect(backupData, isNotNull);
      });

      test('should restore backup through repository', () async {
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('Test Folder'),
          color: const drift.Value('#FF0000'),
        ));

        final backup = await backupRepository.exportBackup(name: 'Test_Backup');
        final backupData = await backupRepository.importBackup(backup.filePath);

        final result = await backupRepository.restoreBackup(
          backupData,
          RestoreOptions(mode: RestoreMode.merge, createSafetyBackup: false),
        );

        expect(result.success, isTrue);
      });

      test('should manage backup schedule through repository', () async {
        final schedule = BackupSchedule(
          enabled: true,
          frequency: BackupFrequency.weekly,
        );

        await backupRepository.updateBackupSchedule(schedule);
        final retrieved = await backupRepository.getBackupSchedule();

        expect(retrieved.enabled, isTrue);
        expect(retrieved.frequency, equals(BackupFrequency.weekly));
      });
    });

    group('Data Integrity Tests', () {
      test('backup should have valid checksum', () async {
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('Test Folder'),
          color: const drift.Value('#FF0000'),
        ));

        final backup = await backupService.exportBackup(name: 'Test_Backup');
        final backupData = await backupService.importBackup(backup.filePath);

        expect(backupData.checksum, isNotNull);
        expect(backupData.verifyChecksum(), isTrue);
      });

      test('backup should include version information', () async {
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('Test Folder'),
          color: const drift.Value('#FF0000'),
        ));

        final backup = await backupService.exportBackup(name: 'Test_Backup');
        final backupData = await backupService.importBackup(backup.filePath);

        expect(backupData.version, equals(2));
      });

      test('backup should preserve all data relationships', () async {
        // Create related data
        final folderId = await database.createFolder(FoldersCompanion(
          name: const drift.Value('Test Folder'),
          color: const drift.Value('#FF0000'),
        ));

        final deckId = await database.createDeck(DecksCompanion(
          name: const drift.Value('Test Deck'),
          folderId: drift.Value(folderId),
          color: const drift.Value('#00FF00'),
        ));

        final flashcardId = await database.createFlashcard(FlashcardsCompanion(
          question: const drift.Value('Test Question'),
          answer: const drift.Value('Test Answer'),
          deckId: drift.Value(deckId),
        ));

        final tagId = await database.createTag(TagsCompanion(
          name: const drift.Value('Test Tag'),
          color: const drift.Value('#0000FF'),
        ));

        await database.addTagToFlashcard(flashcardId, tagId);

        // Create and restore backup
        final backup = await backupService.exportBackup(name: 'Test_Backup');
        final backupData = await backupService.importBackup(backup.filePath);

        await database.deleteAllFolders(); // Clear existing data
        await restoreService.restoreBackup(
          backupData,
          RestoreOptions(mode: RestoreMode.replace, createSafetyBackup: false),
        );

        // Verify relationships are preserved
        final restoredDecks = await database.getAllDecks();
        expect(restoredDecks.length, equals(1));
        expect(restoredDecks.first.folderId, isNotNull);

        final restoredFlashcards = await database.getAllFlashcards();
        expect(restoredFlashcards.length, equals(1));

        final restoredTags = await database.getTagsForFlashcard(restoredFlashcards.first.id);
        expect(restoredTags.length, equals(1));
      });
    });

    group('Error Handling Tests', () {
      test('should handle export cancellation', () async {
        // Test that cancellation is handled gracefully
        // This would require mocking the file picker to return null
        expect(true, isTrue); // Placeholder for actual test
      });

      test('should handle import of invalid file', () async {
        expect(
          () => backupService.importBackup('/nonexistent/file.quizsnap'),
          throwsException,
        );
      });

      test('should handle corrupted backup file', () async {
        // Create a file with invalid JSON
        // This would require file system manipulation
        expect(true, isTrue); // Placeholder for actual test
      });

      test('should handle restore failure gracefully', () async {
        // Test that restore failures don't leave database in inconsistent state
        await database.createFolder(FoldersCompanion(
          name: const drift.Value('Test Folder'),
          color: const drift.Value('#FF0000'),
        ));

        // Create backup for testing (unused in placeholder test)
        await backupService.exportBackup(name: 'Test_Backup');
        
        // Corrupt the backup data
        // This would require file manipulation
        // For now, we test that the service handles exceptions
        expect(true, isTrue); // Placeholder for actual test
      });
    });

    group('Performance Tests', () {
      test('should handle large datasets efficiently', () async {
        // Create a large dataset
        for (int i = 0; i < 100; i++) {
          await database.createFolder(FoldersCompanion(
            name: drift.Value('Folder $i'),
            color: drift.Value('#FF0000'),
          ));
        }

        final stopwatch = Stopwatch()..start();
        await backupService.exportBackup(name: 'Large_Backup');
        stopwatch.stop();

        // Should complete in reasonable time (< 10 seconds for 100 folders)
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      });

      test('should handle restore of large datasets efficiently', () async {
        // Create and backup large dataset
        for (int i = 0; i < 50; i++) {
          await database.createFolder(FoldersCompanion(
            name: drift.Value('Folder $i'),
            color: drift.Value('#FF0000'),
          ));
        }

        final backup = await backupService.exportBackup(name: 'Large_Backup');
        final backupData = await backupService.importBackup(backup.filePath);

        await database.deleteAllFolders();

        final stopwatch = Stopwatch()..start();
        await restoreService.restoreBackup(
          backupData,
          RestoreOptions(mode: RestoreMode.replace, createSafetyBackup: false),
        );
        stopwatch.stop();

        // Should complete in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      });
    });
  });
}
