import 'dart:io';
import '../database/database.dart';
import '../models/backup_enhanced.dart';
import '../services/backup_service_enhanced.dart';
import '../services/restore_service.dart';

class BackupRepository {
  final AppDatabase _database;
  late BackupServiceEnhanced _backupService;
  late RestoreService _restoreService;

  BackupRepository(this._database) {
    _backupService = BackupServiceEnhanced(_database);
    _restoreService = RestoreService(_database, _backupService);
  }

  // Get services
  BackupServiceEnhanced get backupService => _backupService;
  RestoreService get restoreService => _restoreService;

  // Export backup
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

  // Import backup
  Future<BackupData> importBackup(String filePath) async {
    return await _backupService.importBackup(filePath);
  }

  // Get backup file info
  Future<BackupMetadata> getBackupFileInfo(String filePath) async {
    return await _backupService.getBackupFileInfo(filePath);
  }

  // Restore backup
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

  // Delete backup file
  Future<void> deleteBackupFile(String filePath) async {
    await _backupService.deleteBackupFile(filePath);
  }

  // Share backup
  Future<void> shareBackup(String filePath) async {
    await _backupService.shareBackup(filePath);
  }

  // Open backup location
  Future<void> openBackupLocation(String filePath) async {
    await _backupService.openBackupLocation(filePath);
  }

  // Get backup schedule
  Future<BackupSchedule> getBackupSchedule() async {
    return await _backupService.getBackupSchedule();
  }

  // Update backup schedule
  Future<void> updateBackupSchedule(BackupSchedule schedule) async {
    await _backupService.updateBackupSchedule(schedule);
  }

  // Check if automatic backup is due
  Future<bool> isAutomaticBackupDue() async {
    return await _backupService.isAutomaticBackupDue();
  }

  // Perform automatic backup
  Future<BackupFileModel> performAutomaticBackup() async {
    return await _backupService.performAutomaticBackup();
  }

  // Get backup history
  Future<List<BackupMetadata>> getBackupHistory() async {
    return await _backupService.getBackupHistory();
  }

  // Get custom backup path
  Future<String?> getCustomBackupPath() async {
    return await _backupService.getCustomBackupPath();
  }

  // Set custom backup path
  Future<void> setCustomBackupPath(String? path) async {
    await _backupService.setCustomBackupPath(path);
  }

  // Request storage permission
  Future<bool> requestStoragePermission() async {
    return await _backupService.requestStoragePermission();
  }

  // Get default backup directory
  Future<Directory> getDefaultBackupDirectory() async {
    return await _backupService.getDefaultBackupDirectory();
  }

  // Rollback to safety backup
  Future<void> rollbackToSafetyBackup(String safetyBackupId) async {
    await _restoreService.rollbackToSafetyBackup(safetyBackupId);
  }
}
