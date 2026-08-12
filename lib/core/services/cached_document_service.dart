import 'dart:io';
import '../database/database.dart';
import '../models/document_section_model.dart';
import 'document_cache_service.dart';
import 'text_normalization_service.dart';
import 'heading_detection_service.dart';

/// Represents a cached document with rich metadata.
class CachedDocument {
  final int id;
  final String fileName;
  final String filePath;
  final String rawText;
  final String cleanedText;
  final String selectedScope;
  final int totalPages;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;
  final Map<String, dynamic> scopeDetails;

  CachedDocument({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.rawText,
    required this.cleanedText,
    required this.selectedScope,
    this.totalPages = 0,
    this.createdAt,
    this.lastUsedAt,
    this.scopeDetails = const {},
  });

  String get displayName => fileName.split('/').last;

  List<DocumentSection> get sections {
    final raw = scopeDetails['sections'];
    if (raw == null || raw is! List) return [];
    try {
      return raw.map((j) => _sectionFromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static DocumentSection _sectionFromJson(Map<String, dynamic> json) {
    return DocumentSection(
      title: json['title'] as String,
      level: json['level'] as int,
      startLine: json['startLine'] as int,
      endLine: json['endLine'] as int,
      children: (json['children'] as List? ?? [])
          .map((c) => _sectionFromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// High-level service for cached documents. Keeps all metadata in the
/// existing `ExtractedDocuments` table (schema unchanged) using `scopeDetails`.
class CachedDocumentService {
  final DocumentCacheService _cache;

  CachedDocumentService(this._cache);

  /// Caches a document with both raw and cleaned text, plus detected sections.
  Future<int> cacheDocument({
    required String fileName,
    required String filePath,
    required String rawText,
    required String selectedScope,
    String? cleanedText,
    int? totalPages,
    String? source,
  }) async {
    final cleaned = cleanedText ?? TextNormalizationService.reconstruct(rawText);
    final sections = HeadingDetectionService.detectSections(cleaned);

    final scopeDetails = <String, dynamic>{
      'rawText': rawText,
      'cleanedText': cleaned,
      'source': source,
      'totalPages': totalPages ?? 0,
      'sections': sections.map(_sectionToJson).toList(),
    };

    return _cache.cacheDocument(
      fileName: fileName,
      filePath: filePath,
      extractedText: cleaned,
      selectedScope: selectedScope,
      scopeDetails: scopeDetails,
      totalPages: totalPages,
    );
  }

  Future<List<CachedDocument>> getAllCachedDocuments() async {
    final docs = await _cache.getAllCachedDocuments();
    return docs.map(_fromExtractedDocument).toList();
  }

  Future<CachedDocument?> getCachedDocument(int id) async {
    final doc = await _cache.getCachedDocument(id);
    if (doc == null) return null;
    return _fromExtractedDocument(doc);
  }

  Future<bool> deleteCachedDocument(int id) async {
    final doc = await _cache.getCachedDocument(id);
    final success = await _cache.deleteCachedDocument(id);
    if (success && doc != null) {
      try {
        final file = File(doc.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Ignore file-system cleanup errors.
      }
    }
    return success;
  }

  Future<int> getTotalCacheSize() async {
    final docs = await _cache.getAllCachedDocuments();
    int total = 0;
    for (final doc in docs) {
      total += doc.extractedText.length;
      total += doc.filePath.length;
      total += doc.scopeDetails?.length ?? 0;
    }
    // Also include the stored files.
    for (final doc in docs) {
      try {
        final file = File(doc.filePath);
        if (await file.exists()) {
          total += await file.length();
        }
      } catch (_) {}
    }
    return total;
  }

  CachedDocument _fromExtractedDocument(ExtractedDocument doc) {
    final details = _cache.getScopeDetails(doc) ?? {};
    final raw = details['rawText'] as String? ?? doc.extractedText;
    final cleaned = doc.extractedText;
    return CachedDocument(
      id: doc.id,
      fileName: doc.fileName,
      filePath: doc.filePath,
      rawText: raw,
      cleanedText: cleaned,
      selectedScope: doc.selectedScope,
      totalPages: doc.totalPages,
      createdAt: doc.createdAt,
      lastUsedAt: doc.lastUsedAt,
      scopeDetails: details,
    );
  }

  static Map<String, dynamic> _sectionToJson(DocumentSection section) {
    return {
      'title': section.title,
      'level': section.level,
      'startLine': section.startLine,
      'endLine': section.endLine,
      'children': section.children.map(_sectionToJson).toList(),
    };
  }
}
