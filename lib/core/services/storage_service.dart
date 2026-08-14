import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native bridge for Android folder opening and Storage Access Framework (SAF)
/// operations used by the backup system.
///
/// On non-Android platforms all methods are no-ops / return safe defaults so the
/// backup service can call them unconditionally.
class StorageService {
  static const MethodChannel _channel = MethodChannel('quizsnap/folder');

  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  bool get _isAndroid => Platform.isAndroid;

  /// Open a filesystem folder in the device file manager.
  ///
  /// On Android this builds a FileProvider `content://` URI and launches an
  /// `ACTION_VIEW` intent (never a raw `file://` path). Returns `true` if an
  /// intent was successfully launched.
  Future<bool> openFolder(String path) async {
    if (!_isAndroid) {
      // On desktop/iOS we can't reliably open a folder; callers handle the
      // fallback.
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('openFolder', {'path': path});
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[StorageService] openFolder failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[StorageService] openFolder failed: $e');
      return false;
    }
  }

  /// Open a persisted SAF tree URI in the file manager.
  Future<bool> openTreeUri(String uriString) async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('openTreeUri', {'uri': uriString});
      return result ?? false;
    } catch (e) {
      debugPrint('[StorageService] openTreeUri failed: $e');
      return false;
    }
  }

  /// Persist a SAF tree URI permission so it survives app restarts.
  Future<bool> persistTreeUri(String uriString) async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('persistTreeUri', {'uri': uriString});
      return result ?? false;
    } catch (e) {
      debugPrint('[StorageService] persistTreeUri failed: $e');
      return false;
    }
  }

  /// Release a previously persisted SAF tree URI permission.
  Future<bool> releaseTreeUri(String uriString) async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('releaseTreeUri', {'uri': uriString});
      return result ?? false;
    } catch (e) {
      debugPrint('[StorageService] releaseTreeUri failed: $e');
      return false;
    }
  }

  /// Whether a SAF tree URI is currently persisted.
  Future<bool> isTreeUriPersisted(String uriString) async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isTreeUriPersisted', {'uri': uriString});
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Copy a local file into a SAF tree, overwriting any existing file with the
  /// same name. Returns the content URI of the written file, or null on failure.
  Future<String?> copyFileToTreeUri({
    required String treeUri,
    required String fileName,
    required String sourcePath,
  }) async {
    if (!_isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('copyFileToTreeUri', {
        'treeUri': treeUri,
        'fileName': fileName,
        'sourcePath': sourcePath,
      });
    } catch (e) {
      debugPrint('[StorageService] copyFileToTreeUri failed: $e');
      return null;
    }
  }

  /// List files with the given extension inside a SAF tree.
  ///
  /// Returns a list of maps: `{name, size, lastModified}`.
  Future<List<Map<String, dynamic>>> listFilesInTreeUri(
    String treeUri, {
    String extension = 'db',
  }) async {
    if (!_isAndroid) return [];
    try {
      final result = await _channel.invokeMethod<List>('listFilesInTreeUri', {
        'treeUri': treeUri,
        'extension': extension,
      });
      if (result == null) return [];
      return result
          .cast<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    } catch (e) {
      debugPrint('[StorageService] listFilesInTreeUri failed: $e');
      return [];
    }
  }

  /// Copy a file from a SAF tree into the app cache so it can be shared/opened.
  /// Returns the cached file path, or null on failure.
  Future<String?> cacheFileFromTreeUri({
    required String treeUri,
    required String fileName,
  }) async {
    if (!_isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('cacheFileFromTreeUri', {
        'treeUri': treeUri,
        'fileName': fileName,
      });
    } catch (e) {
      debugPrint('[StorageService] cacheFileFromTreeUri failed: $e');
      return null;
    }
  }

  /// Delete a file inside a SAF tree.
  Future<bool> deleteFileInTreeUri({
    required String treeUri,
    required String fileName,
  }) async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('deleteFileInTreeUri', {
        'treeUri': treeUri,
        'fileName': fileName,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get the human-readable display name of a SAF tree folder.
  Future<String?> getFolderDisplayName(String treeUri) async {
    if (!_isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('getFolderDisplayName', {
        'treeUri': treeUri,
      });
    } catch (e) {
      return null;
    }
  }
}
