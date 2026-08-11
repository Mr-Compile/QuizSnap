import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../models/backup_enhanced.dart';
import '../repositories/backup_repository.dart';
import '../services/restore_service.dart';
import '../services/backup_service_enhanced.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Database provider must be initialized in main.dart');
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

// Custom backup path provider
final customBackupPathProvider = FutureProvider<String?>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getCustomBackupPath();
});

// Default backup directory provider
final defaultBackupDirectoryProvider = FutureProvider<Directory>((ref) async {
  final backupService = ref.watch(backupServiceProvider);
  return await backupService.getDefaultBackupDirectory();
});

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
      
      // Refresh backup history
      _ref.invalidate(backupHistoryProvider);
      _ref.invalidate(recentBackupsProvider);
      
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
      
      // Refresh backup history
      _ref.invalidate(backupHistoryProvider);
      _ref.invalidate(recentBackupsProvider);
      
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  // Delete backup file
  Future<bool> deleteBackupFile(String filePath) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _repository.deleteBackupFile(filePath);
      
      state = state.copyWith(isLoading: false);
      
      // Refresh backup files
      _ref.invalidate(backupFilesProvider);
      _ref.invalidate(backupHistoryProvider);
      _ref.invalidate(recentBackupsProvider);
      
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
      
      // Refresh backup history and schedule
      _ref.invalidate(backupHistoryProvider);
      _ref.invalidate(recentBackupsProvider);
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
      
      // Refresh custom path
      _ref.invalidate(customBackupPathProvider);
      
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
      
      // Refresh backup history
      _ref.invalidate(backupHistoryProvider);
      _ref.invalidate(recentBackupsProvider);
      
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
