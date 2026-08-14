import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../models/backup_enhanced.dart';
import '../repositories/backup_repository.dart';
import '../services/restore_service.dart';
import '../services/backup_service_enhanced.dart';

/// Mutable holder for the active [AppDatabase] so the Riverpod [databaseProvider]
/// can be swapped in place after a `.db` restore replaces the underlying file
/// (without restarting the app).
class DatabaseHolder {
  AppDatabase database;
  DatabaseHolder(this.database);
}

// Database holder provider - overridden in main.dart with the real DatabaseHolder.
final databaseHolderProvider = Provider<DatabaseHolder>((ref) {
  throw UnimplementedError(
    'DatabaseHolder must be provided via ProviderScope overrides in main.dart',
  );
});

// Database provider - reads the live database from the holder so it can be
// invalidated & rebuilt after a restore.
final databaseProvider = Provider<AppDatabase>((ref) {
  return ref.watch(databaseHolderProvider).database;
});

// Backup repository provider
final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return BackupRepository(database);
});

// Backup service provider
final backupServiceProvider = Provider<BackupServiceEnhanced>((ref) {
  final repository = ref.watch(backupRepositoryProvider);
  return repository.backupService;
});

// Restore service provider
final restoreServiceProvider = Provider<RestoreService>((ref) {
  final repository = ref.watch(backupRepositoryProvider);
  return repository.restoreService;
});

// Backup schedule provider
final backupScheduleProvider = FutureProvider<BackupSchedule>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getBackupSchedule();
});

// Backup history provider
final backupHistoryProvider = FutureProvider<List<BackupMetadata>>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getBackupHistory();
});

// Recent backups provider (limited to 5)
final recentBackupsProvider = FutureProvider<List<BackupMetadata>>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  final history = await backupService.getBackupHistory();
  return history.take(5).toList();
});

// Backup files provider
final backupFilesProvider = FutureProvider.family<List<BackupFileModel>, String?>((ref, directoryPath) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.listBackupFiles(directoryPath);
});

// Custom backup path provider (legacy filesystem path)
final customBackupPathProvider = FutureProvider<String?>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getCustomBackupPath();
});

// Custom backup SAF tree URI provider (modern custom folder)
final customBackupTreeUriProvider = FutureProvider<String?>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getCustomBackupTreeUri();
});

// Custom backup folder display name provider
final customBackupFolderNameProvider = FutureProvider<String?>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getCustomBackupFolderName();
});

// Default backup directory provider
final defaultBackupDirectoryProvider = FutureProvider<Directory>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getDefaultBackupDirectory();
});

// ─────────────────────────────────────────────────────────────────────
//  Dynamic Backup Settings (Phase 1)
// ─────────────────────────────────────────────────────────────────────
//
// A single, reactive source of truth for the active backup folder. Watches
// the underlying custom-folder providers so it refreshes automatically when
// the user selects a new folder, reverts to default, or restores a backup
// (which swaps the database and rebuilds the service tree).

final backupSettingsProvider =
    FutureProvider<BackupFolderInfo>((ref) async {
  // Watch the custom-folder providers so a change triggers a refresh.
  ref.watch(customBackupTreeUriProvider);
  ref.watch(customBackupFolderNameProvider);
  ref.watch(customBackupPathProvider);

  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getBackupFolderInfo();
});

// ─────────────────────────────────────────────────────────────────────
//  Dynamic Backup Statistics (Phase 7)
// ─────────────────────────────────────────────────────────────────────
//
// Computed live from the actual backup files and database contents. Watches
// [backupSettingsProvider] so statistics refresh whenever the folder or its
// files change.

final backupStatisticsProvider =
    FutureProvider<BackupStatistics>((ref) async {
  final folderInfo = await ref.watch(backupSettingsProvider.future);
  final backupService = ref.watch(backupServiceProvider);
  final dataSummary = await backupService.getDataProtectedSummary();

  return BackupStatistics(
    totalBackups: folderInfo.backupCount,
    lastBackupDate: folderInfo.lastBackupDate,
    totalBackupSizeBytes: folderInfo.totalSizeBytes,
    dataProtected: dataSummary,
    folderInfo: folderInfo,
  );
});

/// Aggregated, UI-facing backup statistics computed from real data.
class BackupStatistics {
  final int totalBackups;
  final DateTime? lastBackupDate;
  final int totalBackupSizeBytes;
  final DataProtectedSummary dataProtected;
  final BackupFolderInfo folderInfo;

  const BackupStatistics({
    required this.totalBackups,
    required this.lastBackupDate,
    required this.totalBackupSizeBytes,
    required this.dataProtected,
    required this.folderInfo,
  });

  String get totalBackupSizeDisplay {
    final bytes = totalBackupSizeBytes;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// Backup operation state provider
class BackupOperationState {
  final bool isLoading;
  final String? errorMessage;
  final BackupFileModel? lastExportedBackup;
  final BackupData? lastImportedBackup;
  final RestoreResult? lastRestoreResult;

  BackupOperationState({
    this.isLoading = false,
    this.errorMessage,
    this.lastExportedBackup,
    this.lastImportedBackup,
    this.lastRestoreResult,
  });

  BackupOperationState copyWith({
    bool? isLoading,
    String? errorMessage,
    BackupFileModel? lastExportedBackup,
    BackupData? lastImportedBackup,
    RestoreResult? lastRestoreResult,
  }) {
    return BackupOperationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastExportedBackup: lastExportedBackup ?? this.lastExportedBackup,
      lastImportedBackup: lastImportedBackup ?? this.lastImportedBackup,
      lastRestoreResult: lastRestoreResult ?? this.lastRestoreResult,
    );
  }

  BackupOperationState clearError() {
    return copyWith(errorMessage: null);
  }

  BackupOperationState clearResults() {
    return copyWith(
      lastExportedBackup: null,
      lastImportedBackup: null,
      lastRestoreResult: null,
    );
  }
}

final backupOperationProvider = StateNotifierProvider<BackupOperationNotifier, BackupOperationState>((ref) {
  final repository = ref.watch(backupRepositoryProvider);
  return BackupOperationNotifier(repository, ref);
});

class BackupOperationNotifier extends StateNotifier<BackupOperationState> {
  final BackupRepository _repository;
  final Ref _ref;

  BackupOperationNotifier(this._repository, this._ref) : super(BackupOperationState());

  /// Invalidate every backup-related Riverpod provider so the Backup & Restore
  /// UI (folder info, statistics, history, file listing, schedule) refreshes
  /// immediately after any mutating operation.
  void _refreshBackupProviders() {
    _ref.invalidate(backupHistoryProvider);
    _ref.invalidate(recentBackupsProvider);
    _ref.invalidate(backupFilesProvider);
    _ref.invalidate(backupSettingsProvider);
    _ref.invalidate(backupStatisticsProvider);
  }

  // Export backup
  Future<BackupFileModel?> exportBackup({
    String? name,
    String? description,
    String? customPath,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final backup = await _repository.exportBackup(
        name: name,
        description: description,
        customPath: customPath,
      );
      
      state = state.copyWith(
        isLoading: false,
        lastExportedBackup: backup,
      );

      // Refresh backup history, file listing, and dynamic settings/stats.
      _refreshBackupProviders();
      
      return backup;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  // Import backup
  Future<BackupData?> importBackup(String filePath) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final backupData = await _repository.importBackup(filePath);
      
      state = state.copyWith(
        isLoading: false,
        lastImportedBackup: backupData,
      );
      
      return backupData;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  // Get backup file info
  Future<BackupMetadata?> getBackupFileInfo(String filePath) async {
    try {
      return await _repository.getBackupFileInfo(filePath);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  // Restore backup
  Future<RestoreResult?> restoreBackup(
    BackupData backupData,
    RestoreOptions options,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _repository.restoreBackup(backupData, options);

      state = state.copyWith(
        isLoading: false,
        lastRestoreResult: result,
      );

      // Refresh backup history, file listing, schedule, and dynamic stats.
      _refreshBackupProviders();
      _ref.invalidate(backupScheduleProvider);

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Restore from a real `.db` file.
  ///
  /// Validates the SQLite header, checkpoints & closes the live database, and
  /// copies the source file over the active database. Then reopens the database
  /// connection by swapping the [DatabaseHolder] and invalidating the Riverpod
  /// tree. Returns the new [AppDatabase] so the UI can adopt it on the Provider
  /// package side via [DatabaseProvider.reopenDatabase].
  Future<AppDatabase?> restoreFromDbFile(String sourcePath) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Cache SAF-backed files into a local path first.
      String localPath = sourcePath;
      final treeUri = await _repository.getCustomBackupTreeUri();
      if (treeUri != null && sourcePath.startsWith(treeUri)) {
        final fileName = sourcePath.substring(treeUri.length + 1);
        localPath = await _repository.cacheSafFileForRestore(
          treeUri: treeUri,
          fileName: fileName,
        );
      }

      // Validate, close current db, copy file.
      await _repository.restoreFromDbFile(localPath);

      // Reopen: create a fresh AppDatabase and swap the holder.
      final newDb = AppDatabase(openConnection());
      _ref.read(databaseHolderProvider).database = newDb;

      // Invalidate the database provider so the whole backup Riverpod tree
      // (repository, services, history, schedule) rebuilds with the new db.
      _ref.invalidate(databaseProvider);
      _ref.invalidate(backupHistoryProvider);
      _ref.invalidate(recentBackupsProvider);
      _ref.invalidate(backupScheduleProvider);
      _ref.invalidate(backupFilesProvider);
      _ref.invalidate(backupSettingsProvider);
      _ref.invalidate(backupStatisticsProvider);
      _ref.invalidate(customBackupPathProvider);
      _ref.invalidate(customBackupTreeUriProvider);
      _ref.invalidate(customBackupFolderNameProvider);

      state = state.copyWith(isLoading: false);

      return newDb;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Validate that a file is a real SQLite database.
  Future<bool> validateSqliteFile(String path) async {
    try {
      return await _repository.validateSqliteFile(path);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Delete backup file
  Future<bool> deleteBackupFile(String filePath) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _repository.deleteBackupFile(filePath);
      
      state = state.copyWith(isLoading: false);

      // Refresh backup files, history, and dynamic settings/stats.
      _refreshBackupProviders();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // Share backup
  Future<bool> shareBackup(String filePath) async {
    try {
      await _repository.shareBackup(filePath);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Open backup location
  Future<bool> openBackupLocation(String filePath) async {
    try {
      await _repository.openBackupLocation(filePath);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Open backup folder in file manager
  Future<bool> openBackupFolder(String folderPath) async {
    try {
      await _repository.openBackupFolder(folderPath);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Copy backup path to clipboard
  Future<bool> copyBackupPath(String filePath) async {
    try {
      await _repository.copyBackupPath(filePath);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Update backup schedule
  Future<bool> updateBackupSchedule(BackupSchedule schedule) async {
    try {
      await _repository.updateBackupSchedule(schedule);
      
      // Refresh schedule
      _ref.invalidate(backupScheduleProvider);
      
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Perform automatic backup
  Future<BackupFileModel?> performAutomaticBackup() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final backup = await _repository.performAutomaticBackup();
      
      state = state.copyWith(
        isLoading: false,
        lastExportedBackup: backup,
      );
      
      // Refresh backup history, schedule, file listing, and dynamic stats.
      _refreshBackupProviders();
      _ref.invalidate(backupScheduleProvider);

      return backup;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  // Set custom backup path
  Future<bool> setCustomBackupPath(String? path) async {
    try {
      await _repository.setCustomBackupPath(path);

      // Refresh custom path + dynamic folder/settings/stats/file listing.
      _ref.invalidate(customBackupPathProvider);
      _ref.invalidate(backupFilesProvider);
      _ref.invalidate(backupSettingsProvider);
      _ref.invalidate(backupStatisticsProvider);

      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Persist a SAF tree URI as the custom backup folder.
  /// Returns the display name on success, null on failure.
  Future<String?> persistCustomTreeUri(String uriString) async {
    try {
      final name = await _repository.persistCustomTreeUri(uriString);
      _ref.invalidate(customBackupTreeUriProvider);
      _ref.invalidate(customBackupFolderNameProvider);
      _ref.invalidate(customBackupPathProvider);
      _ref.invalidate(backupFilesProvider);
      _ref.invalidate(backupSettingsProvider);
      _ref.invalidate(backupStatisticsProvider);
      return name;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  /// Clear the custom backup folder and revert to default app storage.
  Future<bool> clearCustomBackupFolder() async {
    try {
      await _repository.clearCustomBackupFolder();
      _ref.invalidate(customBackupTreeUriProvider);
      _ref.invalidate(customBackupFolderNameProvider);
      _ref.invalidate(customBackupPathProvider);
      _ref.invalidate(backupFilesProvider);
      _ref.invalidate(backupSettingsProvider);
      _ref.invalidate(backupStatisticsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Request storage permission
  Future<bool> requestStoragePermission() async {
    try {
      return await _repository.requestStoragePermission();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Rollback to safety backup
  Future<bool> rollbackToSafetyBackup(String safetyBackupId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _repository.rollbackToSafetyBackup(safetyBackupId);
      
      state = state.copyWith(isLoading: false);

      // Refresh backup history, file listing, and dynamic stats.
      _refreshBackupProviders();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.clearError();
  }

  // Clear results
  void clearResults() {
    state = state.clearResults();
  }
}

// Automatic backup status provider
final automaticBackupStatusProvider = Provider<AutomaticBackupStatus>((ref) {
  final scheduleAsync = ref.watch(backupScheduleProvider);
  final isDueAsync = ref.watch(isAutomaticBackupDueProvider);

  return AutomaticBackupStatus(
    isEnabled: scheduleAsync.value?.enabled ?? false,
    isDue: isDueAsync.value ?? false,
    lastBackupDate: scheduleAsync.value?.lastBackupDate,
    nextBackupDate: scheduleAsync.value?.nextBackupDate,
    frequency: scheduleAsync.value?.frequency ?? BackupFrequency.weekly,
    retention: scheduleAsync.value?.retention ?? BackupRetention.keep5,
  );
});

// Is automatic backup due provider
final isAutomaticBackupDueProvider = FutureProvider<bool>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.isAutomaticBackupDue();
});

// Automatic backup status class
class AutomaticBackupStatus {
  final bool isEnabled;
  final bool isDue;
  final DateTime? lastBackupDate;
  final DateTime? nextBackupDate;
  final BackupFrequency frequency;
  final BackupRetention retention;

  AutomaticBackupStatus({
    required this.isEnabled,
    required this.isDue,
    this.lastBackupDate,
    this.nextBackupDate,
    required this.frequency,
    required this.retention,
  });

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
}
