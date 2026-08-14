import 'dart:io';
import '../database/database.dart';
import '../models/backup_enhanced.dart';
import '../services/backup_service_enhanced.dart';
import '../services/restore_service.dart';
import '../services/storage_service.dart';

class BackupRepository {
  final AppDatabase _database;
  late BackupServiceEnhanced _backupService;
  late RestoreService _restoreService;

  BackupRepository(this._database) {
    _backupService = BackupServiceEnhanced(_database, StorageService());
    _restoreService = RestoreService(_database, _backupService);
  }

  // Get services
  BackupServiceEnhanced get backupService => _backupService;
  RestoreService get restoreService => _restoreService;

  // Export backup (real .db)
  Future<BackupFileModel> exportBackup({
    String? name,
    String? description,
    String? customPath,
  }) async {
    return await _backupService.exportBackup(
      name: name,
      description: description,
      customPath: customPath,
    );
  }

  // Restore from a real .db file (validates, closes db, copies file).
  // Caller must reopen the database afterwards.
  Future<void> restoreFromDbFile(String sourcePath) async {
    await _backupService.restoreFromDbFile(sourcePath);
  }

  // Validate a file is a real SQLite database.
  Future<bool> validateSqliteFile(String path) async {
    return await _backupService.validateSqliteFile(path);
  }

  // Materialise a SAF-backed backup file into the app cache for restore.
  Future<String> cacheSafFileForRestore({
    required String treeUri,
    required String fileName,
  }) async {
    return await _backupService.cacheSafFileForRestore(
      treeUri: treeUri,
      fileName: fileName,
    );
  }

  // Legacy JSON import (old .quizsnap / .json backups)
  Future<BackupData> importBackup(String filePath) async {
    return await _backupService.importBackup(filePath);
  }

  Future<BackupMetadata> getBackupFileInfo(String filePath) async {
    return await _backupService.getBackupFileInfo(filePath);
  }

  // Legacy JSON restore (old backups)
  Future<RestoreResult> restoreBackup(
    BackupData backupData,
    RestoreOptions options,
  ) async {
    return await _restoreService.restoreBackup(backupData, options);
  }

  // List backup files
  Future<List<BackupFileModel>> listBackupFiles([String? directoryPath]) async {
    return await _backupService.listBackupFiles(directoryPath);
  }

  Future<void> deleteBackupFile(String filePath) async {
    await _backupService.deleteBackupFile(filePath);
  }

  Future<void> shareBackup(String filePath) async {
    await _backupService.shareBackup(filePath);
  }

  Future<void> openBackupLocation(String filePath) async {
    await _backupService.openBackupLocation(filePath);
  }

  Future<void> openBackupFolder(String folderPath) async {
    await _backupService.openBackupFolder(folderPath);
  }

  Future<void> copyBackupPath(String filePath) async {
    await _backupService.copyBackupPath(filePath);
  }

  Future<BackupSchedule> getBackupSchedule() async {
    return await _backupService.getBackupSchedule();
  }

  Future<void> updateBackupSchedule(BackupSchedule schedule) async {
    await _backupService.updateBackupSchedule(schedule);
  }

  Future<bool> isAutomaticBackupDue() async {
    return await _backupService.isAutomaticBackupDue();
  }

  Future<BackupFileModel> performAutomaticBackup() async {
    return await _backupService.performAutomaticBackup();
  }

  Future<List<BackupMetadata>> getBackupHistory() async {
    return await _backupService.getBackupHistory();
  }

  // Custom backup path (legacy filesystem path)
  Future<String?> getCustomBackupPath() async {
    return await _backupService.getCustomBackupPath();
  }

  Future<void> setCustomBackupPath(String? path) async {
    await _backupService.setCustomBackupPath(path);
  }

  // SAF tree URI (modern custom folder)
  Future<String?> getCustomBackupTreeUri() async {
    return await _backupService.getCustomBackupTreeUri();
  }

  Future<String?> getCustomBackupFolderName() async {
    return await _backupService.getCustomBackupFolderName();
  }

  Future<String?> persistCustomTreeUri(String uriString) async {
    return await _backupService.persistCustomTreeUri(uriString);
  }

  Future<void> clearCustomBackupFolder() async {
    await _backupService.clearCustomBackupFolder();
  }

  Future<bool> requestStoragePermission() async {
    return await _backupService.requestStoragePermission();
  }

  Future<Directory> getDefaultBackupDirectory() async {
    return await _backupService.getDefaultBackupDirectory();
  }

  Future<void> rollbackToSafetyBackup(String safetyBackupId) async {
    await _restoreService.rollbackToSafetyBackup(safetyBackupId);
  }
}
