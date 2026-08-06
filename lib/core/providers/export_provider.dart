import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../models/export.dart';
import '../models/backup.dart';
import '../services/export_service.dart';
import '../services/backup_service.dart';

class ExportProvider with ChangeNotifier {
  final AppDatabase _database;
  late ExportService _exportService;
  late BackupService _backupService;
  
  List<ExportResult> _exportHistory = [];
  List<BackupMetadata> _backupHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  ExportProvider(this._database) {
    _exportService = ExportService(_database);
    _backupService = BackupService(_database);
    _loadBackupHistory();
  }

  // Getters
  ExportService get exportService => _exportService;
  BackupService get backupService => _backupService;
  List<ExportResult> get exportHistory => _exportHistory;
  List<BackupMetadata> get backupHistory => _backupHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Export methods
  Future<ExportResult?> exportData(ExportOptions options, {int? deckId}) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _exportService.exportData(options, deckId: deckId);
      _exportHistory.add(result);
      _setLoading(false);
      return result;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<void> shareExport(String filePath) async {
    await _exportService.shareExport(filePath);
  }

  Future<void> printPdf(String filePath) async {
    await _exportService.printPdf(filePath);
  }

  // Backup methods
  Future<BackupMetadata?> createBackup({
    String? name,
    String? description,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final backup = await _backupService.createBackup(
        name: name,
        description: description,
      );
      await _loadBackupHistory();
      _setLoading(false);
      return backup;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<BackupMetadata?> restoreBackup(String backupId) async {
    _setLoading(true);
    _clearError();

    try {
      final backup = await _backupService.restoreBackup(backupId);
      await _loadBackupHistory();
      _setLoading(false);
      return backup;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<void> deleteBackup(String backupId) async {
    _setLoading(true);
    _clearError();

    try {
      await _backupService.deleteBackup(backupId);
      await _loadBackupHistory();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
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

  Future<BackupMetadata?> performAutomaticBackup() async {
    _setLoading(true);
    _clearError();

    try {
      final backup = await _backupService.performAutomaticBackup();
      await _loadBackupHistory();
      _setLoading(false);
      return backup;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // Private methods
  Future<void> _loadBackupHistory() async {
    _backupHistory = await _backupService.getBackupHistory();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}