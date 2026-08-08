import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import 'document_extraction_service.dart';

class DocumentCacheService {
  final DatabaseProvider _databaseProvider;

  DocumentCacheService(this._databaseProvider);

  /// Cache extracted document with scope information
  Future<int> cacheDocument({
    required String fileName,
    required String filePath,
    required String extractedText,
    required String selectedScope,
    Map<String, dynamic>? scopeDetails,
    int? totalPages,
  }) async {
    final db = _databaseProvider.database;

    final stats = DocumentExtractionService.getTextStatistics(extractedText);

    return await db.createExtractedDocument(ExtractedDocumentsCompanion(
      fileName: Value(fileName),
      filePath: Value(filePath),
      extractedText: Value(extractedText),
      selectedScope: Value(selectedScope),
      scopeDetails: scopeDetails != null ? Value(jsonEncode(scopeDetails)) : const Value.absent(),
      totalPages: Value(totalPages ?? 0),
      characterCount: Value(stats['characters'] ?? 0),
      createdAt: Value(DateTime.now()),
      lastUsedAt: Value(DateTime.now()),
    ));
  }

  /// Get cached document by ID
  Future<ExtractedDocument?> getCachedDocument(int id) async {
    final db = _databaseProvider.database;

    final doc = await db.getExtractedDocumentById(id);
    if (doc != null) {
      // Update last used timestamp
      await db.updateDocumentLastUsed(id);
    }
    return doc;
  }

  /// Get all cached documents
  Future<List<ExtractedDocument>> getAllCachedDocuments() async {
    final db = _databaseProvider.database;

    return await db.getAllExtractedDocuments();
  }

  /// Search cached documents by filename
  Future<List<ExtractedDocument>> searchDocuments(String query) async {
    final db = _databaseProvider.database;

    return await db.searchExtractedDocuments(query);
  }

  /// Update cached document
  Future<bool> updateCachedDocument(ExtractedDocument document) async {
    final db = _databaseProvider.database;

    return await db.updateExtractedDocument(document);
  }

  /// Delete cached document
  Future<bool> deleteCachedDocument(int id) async {
    final db = _databaseProvider.database;

    return await db.deleteExtractedDocument(id);
  }

  /// Clear old cache (documents not used in 30 days)
  Future<int> clearOldCache() async {
    final db = _databaseProvider.database;

    final documents = await db.getAllExtractedDocuments();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    int deletedCount = 0;
    for (final doc in documents) {
      if (doc.lastUsedAt != null && doc.lastUsedAt!.isBefore(thirtyDaysAgo)) {
        await db.deleteExtractedDocument(doc.id);
        deletedCount++;
      }
    }

    return deletedCount;
  }

  /// Get scope details from JSON string
  Map<String, dynamic>? getScopeDetails(ExtractedDocument document) {
    if (document.scopeDetails == null) return null;
    try {
      return jsonDecode(document.scopeDetails!);
    } catch (e) {
      return null;
    }
  }

  /// Check if document exists in cache
  Future<bool> isDocumentCached(String filePath) async {
    final db = _databaseProvider.database;

    final documents = await db.getAllExtractedDocuments();
    return documents.any((doc) => doc.filePath == filePath);
  }

  /// Get cached document by file path
  Future<ExtractedDocument?> getCachedDocumentByPath(String filePath) async {
    final db = _databaseProvider.database;

    final documents = await db.getAllExtractedDocuments();
    try {
      return documents.firstWhere((doc) => doc.filePath == filePath);
    } catch (e) {
      return null;
    }
  }
}