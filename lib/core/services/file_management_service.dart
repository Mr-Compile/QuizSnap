import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileManagementService {
  static final FileManagementService _instance = FileManagementService._internal();
  factory FileManagementService() => _instance;
  FileManagementService._internal();

  /// Get the app's private documents directory
  Future<Directory> get _appDocumentsDirectory async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final documentsDir = Directory(p.join(appDocDir.path, 'documents'));
    
    if (!await documentsDir.exists()) {
      await documentsDir.create(recursive: true);
    }
    
    return documentsDir;
  }

  /// Copy a file to the app's private documents directory
  /// Returns the path to the copied file
  Future<String> copyFileToAppStorage(File sourceFile) async {
    try {
      final documentsDir = await _appDocumentsDirectory;
      final fileName = p.basename(sourceFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${timestamp}_$fileName';
      final targetPath = p.join(documentsDir.path, newFileName);
      
      await sourceFile.copy(targetPath);
      
      return targetPath;
    } catch (e) {
      throw Exception('Failed to copy file to app storage: $e');
    }
  }

  /// Delete a file from app storage
  Future<bool> deleteFileFromAppStorage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to delete file from app storage: $e');
    }
  }

  /// Check if a file exists in app storage
  Future<bool> fileExistsInAppStorage(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get all files in the app storage directory
  Future<List<File>> getAllFilesInStorage() async {
    try {
      final documentsDir = await _appDocumentsDirectory;
      final entities = await documentsDir.list().toList();
      
      return entities.whereType<File>().toList();
    } catch (e) {
      throw Exception('Failed to list files in app storage: $e');
    }
  }

  /// Get the size of a file in bytes
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Clear old files from storage (older than specified days)
  Future<int> clearOldFiles({int daysOld = 30}) async {
    try {
      final documentsDir = await _appDocumentsDirectory;
      final entities = await documentsDir.list().toList();
      final files = entities.whereType<File>();
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      int deletedCount = 0;
      
      for (final file in files) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          await file.delete();
          deletedCount++;
        }
      }
      
      return deletedCount;
    } catch (e) {
      throw Exception('Failed to clear old files: $e');
    }
  }

  /// Get total storage size used by documents
  Future<int> getTotalStorageSize() async {
    try {
      final files = await getAllFilesInStorage();
      int totalSize = 0;
      
      for (final file in files) {
        totalSize += await file.length();
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}