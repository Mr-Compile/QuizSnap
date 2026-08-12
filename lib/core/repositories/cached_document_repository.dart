import 'package:flutter/foundation.dart';
import '../providers/database_provider.dart';
import '../services/cached_document_service.dart';
import '../services/document_cache_service.dart';

class CachedDocumentRepository with ChangeNotifier {
  final CachedDocumentService _service;
  List<CachedDocument> _documents = [];
  bool _isLoading = false;
  String? _error;

  CachedDocumentRepository(DatabaseProvider dbProvider)
      : _service = CachedDocumentService(DocumentCacheService(dbProvider));

  List<CachedDocument> get documents => List.unmodifiable(_documents);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _documents = await _service.getAllCachedDocuments();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<CachedDocument?> get(int id) async {
    try {
      return await _service.getCachedDocument(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<void> delete(int id) async {
    final success = await _service.deleteCachedDocument(id);
    if (success) {
      await load();
    }
  }

  Future<int> get totalCacheSize => _service.getTotalCacheSize();
}
