import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../models/backup_enhanced.dart';
import 'storage_service.dart';

class BackupServiceEnhanced {
  final AppDatabase _database;
  final StorageService _storage;

  static const String _backupScheduleKey = 'backup_schedule_enhanced';
  static const String _backupHistoryKey = 'backup_history_enhanced';
  static const String _customBackupPathKey = 'custom_backup_path';
  static const String _customBackupTreeUriKey = 'custom_backup_tree_uri';
  static const String _customBackupFolderNameKey = 'custom_backup_folder_name';

  /// SQLite database file name used by [openConnection].
  static const String databaseFileName = 'quizsnap.db';

  BackupServiceEnhanced(this._database, [StorageService? storage])
      : _storage = storage ?? StorageService();

  // ─────────────────────────────────────────────────────────────────────
  //  Real SQLite database export (.db)
  // ─────────────────────────────────────────────────────────────────────

  /// Export a real SQLite database backup.
  ///
  /// Checkpoints the WAL into the main database file, then copies the live
  /// `quizsnap.db` to the backup folder (filesystem path or SAF tree URI) as
  /// `quizsnap_backup_YYYYMMDD_HHMMSS.db`.
  Future<BackupFileModel> exportBackup({
    String? name,
    String? description,
    String? customPath,
  }) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupName = name ?? 'quizsnap_backup_$timestamp';
    // Always enforce the .db extension for real database backups.
    final fileName = backupName.toLowerCase().endsWith('.db')
        ? backupName
        : '$backupName.db';

    final backupId = DateTime.now().millisecondsSinceEpoch.toString();
    final metadata = BackupMetadata(
      id: backupId,
      type: BackupType.manual,
      status: BackupStatus.creating,
      name: fileName,
      description: description,
      version: 2,
      createdAt: DateTime.now(),
      deckCount: 0,
      flashcardCount: 0,
      folderCount: 0,
      tagCount: 0,
    );

    try {
      // 1. Checkpoint WAL so all committed pages are in the main db file.
      await _checkpointDatabase();

      // 2. Locate the live database file.
      final dbFile = await _getDatabaseFile();
      if (!await dbFile.exists()) {
        throw Exception('Database file not found at ${dbFile.path}');
      }

      // 3. Determine destination.
      final treeUri = await getCustomBackupTreeUri();
      String savedFilePath;

      if (treeUri != null) {
        // Custom SAF folder: copy via native bridge.
        final writtenUri = await _storage.copyFileToTreeUri(
          treeUri: treeUri,
          fileName: fileName,
          sourcePath: dbFile.path,
        );
        if (writtenUri == null) {
          throw Exception('Failed to write backup to the selected folder');
        }
        // Store a synthetic path so the rest of the app can resolve it.
        savedFilePath = '$treeUri/$fileName';
      } else {
        final backupDir = customPath != null
            ? Directory(customPath)
            : await getDefaultBackupDirectory();
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        savedFilePath = p.join(backupDir.path, fileName);
        await dbFile.copy(savedFilePath);
      }

      // 4. Read file size. For SAF files we use the listing API.
      final fileSize = await _getFileSize(savedFilePath, treeUri, fileName);

      // 5. Record metadata + history.
      final finalMetadata = metadata.copyWith(
        status: BackupStatus.completed,
        completedAt: DateTime.now(),
        fileSizeBytes: fileSize,
        filePath: savedFilePath,
      );
      await _addToBackupHistory(finalMetadata);

      // Build a BackupFileModel. For SAF files we don't have a File handle, so
      // construct directly.
      if (treeUri != null) {
        return BackupFileModel(
          fileName: fileName,
          filePath: savedFilePath,
          fileSizeBytes: fileSize,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          metadata: finalMetadata,
        );
      }
      return BackupFileModel.fromFile(File(savedFilePath), finalMetadata);
    } catch (e) {
      await _addToBackupHistory(metadata.copyWith(
        status: BackupStatus.failed,
        completedAt: DateTime.now(),
      ));
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Restore from .db
  // ─────────────────────────────────────────────────────────────────────

  /// Validate that a file is a real SQLite database by checking its header.
  Future<bool> validateSqliteFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      final raf = await file.open();
      try {
        final bytes = await raf.read(16);
        // SQLite header: "SQLite format 3\0"
        const header = 'SQLite format 3\u0000';
        if (bytes.length < 16) return false;
        final decoded = String.fromCharCodes(bytes);
        return decoded == header;
      } finally {
        await raf.close();
      }
    } catch (e) {
      debugPrint('[BackupService] validateSqliteFile failed: $e');
      return false;
    }
  }

  /// Restore from a real SQLite `.db` file.
  ///
  /// Validates the SQLite header, checkpoints & closes the live database,
  /// removes stale WAL/SHM files, then copies the source `.db` over the active
  /// database path. The caller is responsible for reopening the database
  /// connection (see [BackupOperationNotifier] / [DatabaseProvider.reopenDatabase]).
  ///
  /// [sourcePath] must be a filesystem path. For SAF-backed files use
  /// [cacheSafFileForRestore] first to materialise a local copy.
  Future<void> restoreFromDbFile(String sourcePath) async {
    if (!await validateSqliteFile(sourcePath)) {
      throw Exception('The selected file is not a valid SQLite database');
    }

    final dbFile = await _getDatabaseFile();
    final walFile = File('${dbFile.path}-wal');
    final shmFile = File('${dbFile.path}-shm');

    // Checkpoint & close the active connection so the file is consistent.
    try {
      await _checkpointDatabase();
    } catch (e) {
      debugPrint('[BackupService] checkpoint before restore failed: $e');
    }
    await _database.close();

    // Remove stale WAL/SHM so the restored db opens cleanly.
    if (await walFile.exists()) {
      try {
        await walFile.delete();
      } catch (_) {}
    }
    if (await shmFile.exists()) {
      try {
        await shmFile.delete();
      } catch (_) {}
    }

    // Replace the database file.
    final source = File(sourcePath);
    await source.copy(dbFile.path);
  }

  /// Materialise a SAF-backed backup file into the app cache so it can be
  /// validated and restored. Returns the cached filesystem path.
  Future<String> cacheSafFileForRestore({
    required String treeUri,
    required String fileName,
  }) async {
    final cached = await _storage.cacheFileFromTreeUri(
      treeUri: treeUri,
      fileName: fileName,
    );
    if (cached == null) {
      throw Exception('Could not access the backup file in the selected folder');
    }
    return cached;
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Legacy JSON import (kept for backward compatibility with old .quizsnap
  //  and .json backups created by previous app versions).
  // ─────────────────────────────────────────────────────────────────────

  Future<BackupData> importBackup(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Backup file not found');
    }

    final jsonString = await file.readAsString();
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;

    if (!jsonData.containsKey('version') || !jsonData.containsKey('metadata')) {
      throw Exception('Invalid backup file structure');
    }

    final backupData = BackupData.fromJson(jsonData);

    if (backupData.checksum != null && !backupData.verifyChecksum()) {
      throw Exception('Backup file integrity check failed');
    }

    if (backupData.version > 2) {
      throw Exception('Backup version ${backupData.version} is not supported');
    }

    return backupData;
  }

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

    final metadata =
        BackupMetadata.fromJson(jsonData['metadata'] as Map<String, dynamic>);
    final stat = await file.stat();

    return metadata.copyWith(
      fileSizeBytes: stat.size,
      filePath: filePath,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Share / open
  // ─────────────────────────────────────────────────────────────────────

  Future<void> shareBackup(String filePath) async {
    // For SAF-backed files (filePath looks like "<treeUri>/<fileName>"),
    // materialise a cache copy first so share_plus can attach a real file.
    final file = await _resolveShareableFile(filePath);
    if (file == null || !await file.exists()) {
      throw Exception('Backup file not found');
    }
    await share_plus.Share.shareXFiles(
      [share_plus.XFile(file.path)],
      text: 'QuizSnap Backup',
    );
  }

  Future<void> openBackupLocation(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }
    await share_plus.Share.shareXFiles(
      [share_plus.XFile(filePath)],
      text: 'QuizSnap Backup File',
    );
  }

  /// Open the backup folder in the device file manager.
  ///
  /// - Default (app-specific) folder: opens via a FileProvider `content://`
  ///   URI through the native bridge (never a raw filesystem path).
  /// - Custom SAF folder: reopens the persisted tree URI.
  Future<void> openBackupFolder(String folderPath) async {
    final treeUri = await getCustomBackupTreeUri();
    if (treeUri != null) {
      final ok = await _storage.openTreeUri(treeUri);
      if (ok) return;
      throw Exception('Could not open folder in file manager');
    }

    final directory = Directory(folderPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final ok = await _storage.openFolder(folderPath);
    if (!ok) {
      throw Exception('Could not open folder in file manager');
    }
  }

  Future<void> copyBackupPath(String filePath) async {
    await Clipboard.setData(ClipboardData(text: filePath));
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Delete
  // ─────────────────────────────────────────────────────────────────────

  Future<void> deleteBackupFile(String filePath) async {
    final treeUri = await getCustomBackupTreeUri();
    if (treeUri != null && filePath.startsWith(treeUri)) {
      final fileName = filePath.substring(treeUri.length + 1);
      await _storage.deleteFileInTreeUri(treeUri: treeUri, fileName: fileName);
    } else {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    // Remove from history by file name.
    final history = await getBackupHistory();
    final fileName = _fileNameFromPath(filePath);
    final updatedHistory = history.where((b) {
      final bFileName = b.filePath == null ? null : _fileNameFromPath(b.filePath!);
      return bFileName != fileName;
    }).toList();
    await _saveBackupHistory(updatedHistory);
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Custom backup path / SAF tree URI
  // ─────────────────────────────────────────────────────────────────────

  Future<String?> getCustomBackupPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customBackupPathKey);
  }

  Future<void> setCustomBackupPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_customBackupPathKey);
    } else {
      await prefs.setString(_customBackupPathKey, path);
    }
  }

  Future<String?> getCustomBackupTreeUri() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customBackupTreeUriKey);
  }

  Future<void> setCustomBackupTreeUri(String? uri) async {
    final prefs = await SharedPreferences.getInstance();
    if (uri == null) {
      await prefs.remove(_customBackupTreeUriKey);
      await prefs.remove(_customBackupFolderNameKey);
    } else {
      await prefs.setString(_customBackupTreeUriKey, uri);
    }
  }

  Future<String?> getCustomBackupFolderName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customBackupFolderNameKey);
  }

  Future<void> setCustomBackupFolderName(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (name == null) {
      await prefs.remove(_customBackupFolderNameKey);
    } else {
      await prefs.setString(_customBackupFolderNameKey, name);
    }
  }

  /// Persist a SAF tree URI permission and store it as the custom backup folder.
  /// Returns the human-readable folder name, or null on failure.
  Future<String?> persistCustomTreeUri(String uriString) async {
    final ok = await _storage.persistTreeUri(uriString);
    if (!ok) return null;
    await setCustomBackupTreeUri(uriString);
    // Clear the legacy filesystem path since we now use SAF.
    await setCustomBackupPath(null);
    final displayName = await _storage.getFolderDisplayName(uriString);
    await setCustomBackupFolderName(displayName ?? 'Custom folder');
    return displayName ?? 'Custom folder';
  }

  /// Clear the custom backup folder (revert to default app storage).
  Future<void> clearCustomBackupFolder() async {
    final treeUri = await getCustomBackupTreeUri();
    if (treeUri != null) {
      await _storage.releaseTreeUri(treeUri);
    }
    await setCustomBackupTreeUri(null);
    await setCustomBackupPath(null);
  }

  // Storage permission is no longer requested (app-private storage + SAF need
  // none). Kept for backward compatibility.
  Future<bool> requestStoragePermission() async {
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Default backup directory
  // ─────────────────────────────────────────────────────────────────────

  Future<Directory> getDefaultBackupDirectory() async {
    Directory baseDir;
    if (Platform.isAndroid) {
      baseDir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }
    final backupDir = Directory(p.join(baseDir.path, 'QuizSnap', 'Backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  // ─────────────────────────────────────────────────────────────────────
  //  List backup files
  // ─────────────────────────────────────────────────────────────────────

  /// List `.db` backup files, newest first. Reads from the SAF tree when a
  /// custom folder is configured, otherwise from the default filesystem folder.
  Future<List<BackupFileModel>> listBackupFiles([String? directoryPath]) async {
    try {
      final treeUri = await getCustomBackupTreeUri();
      if (treeUri != null) {
        final entries = await _storage.listFilesInTreeUri(treeUri);
        final models = entries.map((e) => BackupFileModel.fromSafEntry(
              name: e['name'] as String,
              size: (e['size'] as num).toInt(),
              lastModified: (e['lastModified'] as num).toInt(),
              treeUri: treeUri,
            ));
        final list = models.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }

      final directory = directoryPath != null
          ? Directory(directoryPath)
          : await getDefaultBackupDirectory();

      if (!await directory.exists()) return [];

      final files = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.db'))
          .toList();

      final backupFiles = <BackupFileModel>[];
      for (final file in files) {
        try {
          backupFiles.add(BackupFileModel.fromDbFile(file));
        } catch (_) {
          continue;
        }
      }

      return backupFiles..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('[BackupService] listBackupFiles failed: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Schedule / automatic backup
  // ─────────────────────────────────────────────────────────────────────

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

    final schedule = BackupSchedule.fromJson(
        json.decode(scheduleJson) as Map<String, dynamic>);
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

    // Retention: keep the latest 10 backups (auto backups).
    await _cleanupOldBackups(10, schedule.customBackupPath);

    final backup = await exportBackup(
      name: 'quizsnap_backup_auto_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
      description: 'Automatic backup',
      customPath: schedule.customBackupPath,
    );

    final nextBackupDate =
        DateTime.now().add(Duration(days: schedule.intervalDays));
    await updateBackupSchedule(schedule.copyWith(
      lastBackupDate: DateTime.now(),
      nextBackupDate: nextBackupDate,
    ));

    return backup;
  }

  Future<void> _cleanupOldBackups(int maxBackups, String? customPath) async {
    try {
      final backups = await listBackupFiles(customPath);
      if (backups.length <= maxBackups) return;

      final backupsToDelete = backups.skip(maxBackups).toList();
      for (final backup in backupsToDelete) {
        try {
          await deleteBackupFile(backup.filePath);
          await _removeFromBackupHistory(backup.metadata.id);
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      debugPrint('[BackupService] _cleanupOldBackups failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  History
  // ─────────────────────────────────────────────────────────────────────

  Future<List<BackupMetadata>> getBackupHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_backupHistoryKey);
      if (historyJson == null) return [];

      final List<dynamic> decoded = json.decode(historyJson);
      final history = decoded
          .map((e) => BackupMetadata.fromJson(e as Map<String, dynamic>))
          .toList();
      // Newest first.
      history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return history;
    } catch (e) {
      debugPrint('[BackupService] getBackupHistory failed: $e');
      return [];
    }
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

  // ─────────────────────────────────────────────────────────────────────
  //  Database helpers
  // ─────────────────────────────────────────────────────────────────────

  Future<File> _getDatabaseFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return File(p.join(dbFolder.path, databaseFileName));
  }

  Future<void> _checkpointDatabase() async {
    try {
      await _database.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (e) {
      // WAL may not be enabled; safe to ignore.
      debugPrint('[BackupService] wal_checkpoint failed: $e');
    }
  }

  Future<int> _getFileSize(
      String savedFilePath, String? treeUri, String fileName) async {
    if (treeUri != null) {
      final entries = await _storage.listFilesInTreeUri(treeUri);
      final match = entries.firstWhere(
        (e) => (e['name'] as String) == fileName,
        orElse: () => <String, dynamic>{'size': 0},
      );
      final size = match['size'];
      return size is num ? size.toInt() : 0;
    }
    final file = File(savedFilePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Resolve a stored filePath into a real filesystem [File] that can be
  /// shared. SAF-backed paths are cached locally first.
  Future<File?> _resolveShareableFile(String filePath) async {
    final treeUri = await getCustomBackupTreeUri();
    if (treeUri != null && filePath.startsWith(treeUri)) {
      final fileName = filePath.substring(treeUri.length + 1);
      final cached = await _storage.cacheFileFromTreeUri(
        treeUri: treeUri,
        fileName: fileName,
      );
      if (cached == null) return null;
      return File(cached);
    }
    return File(filePath);
  }

  String _fileNameFromPath(String path) {
    if (path.contains('/')) return path.split('/').last;
    if (path.contains('\\')) return path.split('\\').last;
    return path;
  }
}
