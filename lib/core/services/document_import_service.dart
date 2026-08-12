import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/database_provider.dart';
import 'document_extraction_service.dart';
import 'document_cache_service.dart';
import 'file_management_service.dart';

enum DocumentType {
  pdf,
  txt,
  docx,
}

enum DocumentScope {
  entireDocument,
  specificPages,
  byHeadings,
  highlightedText,
}

class ImportResult {
  final int? id;
  final bool success;
  final String? extractedText;
  final String? filePath;
  final String? error;
  final DocumentType documentType;
  final int? totalPages;

  ImportResult({
    this.id,
    required this.success,
    this.extractedText,
    this.filePath,
    this.error,
    required this.documentType,
    this.totalPages,
  });
}

class DocumentImportService {
  final FileManagementService _fileManagementService;
  final DocumentCacheService _cacheService;

  DocumentImportService(DatabaseProvider databaseProvider)
      : _fileManagementService = FileManagementService(),
        _cacheService = DocumentCacheService(databaseProvider);

  /// Unified document import pipeline
  /// 
  /// This method handles the complete import flow:
  /// 1. Pick file
  /// 2. Copy to app storage
  /// 3. Detect file type
  /// 4. Extract text
  /// 5. Cache extracted text
  /// 
  /// Returns ImportResult with extracted text and file info
  Future<ImportResult> importDocument() async {
    try {
      // Step 1: Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return ImportResult(
          success: false,
          error: 'Storage permission is required to import documents',
          documentType: DocumentType.txt,
        );
      }

      // Step 2: Pick file
      final fileResult = await _pickFile();
      if (fileResult == null) {
        return ImportResult(
          success: false,
          error: 'No file selected',
          documentType: DocumentType.txt,
        );
      }

      final originalFile = File(fileResult.files.single.path!);
      final documentType = _detectDocumentType(originalFile);

      // Step 3: Copy to app storage
      final copiedFilePath = await _fileManagementService.copyFileToAppStorage(originalFile);
      final copiedFile = File(copiedFilePath);

      // Step 4: Extract text
      String extractedText;
      try {
        extractedText = await DocumentExtractionService.extractFromFile(copiedFile);
        extractedText = DocumentExtractionService.cleanText(extractedText);
      } catch (e) {
        // Clean up copied file if extraction fails
        await _fileManagementService.deleteFileFromAppStorage(copiedFilePath);
        return ImportResult(
          success: false,
          error: 'Failed to extract text: $e',
          documentType: documentType,
        );
      }

      // Step 5: Cache the document
      await _cacheService.cacheDocument(
        fileName: originalFile.path.split('/').last,
        filePath: copiedFilePath,
        extractedText: extractedText,
        selectedScope: 'all',
        scopeDetails: null,
        totalPages: null,
      );

      return ImportResult(
        success: true,
        extractedText: extractedText,
        filePath: copiedFilePath,
        documentType: documentType,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Import failed: $e',
        documentType: DocumentType.txt,
      );
    }
  }

  /// Import document with specific file type filter
  Future<ImportResult> importDocumentOfType(DocumentType type) async {
    try {
      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return ImportResult(
          success: false,
          error: 'Storage permission is required to import documents',
          documentType: type,
        );
      }

      // Pick file with specific type
      final fileResult = await _pickFileOfType(type);
      if (fileResult == null) {
        return ImportResult(
          success: false,
          error: 'No file selected',
          documentType: type,
        );
      }

      final originalFile = File(fileResult.files.single.path!);

      // Copy to app storage
      final copiedFilePath = await _fileManagementService.copyFileToAppStorage(originalFile);
      final copiedFile = File(copiedFilePath);

      // Extract text
      String extractedText;
      try {
        extractedText = await DocumentExtractionService.extractFromFile(copiedFile);
        extractedText = DocumentExtractionService.cleanText(extractedText);
      } catch (e) {
        await _fileManagementService.deleteFileFromAppStorage(copiedFilePath);
        return ImportResult(
          success: false,
          error: 'Failed to extract text: $e',
          documentType: type,
        );
      }

      // Cache the document
      await _cacheService.cacheDocument(
        fileName: originalFile.path.split('/').last,
        filePath: copiedFilePath,
        extractedText: extractedText,
        selectedScope: 'all',
        scopeDetails: null,
        totalPages: null,
      );

      return ImportResult(
        success: true,
        extractedText: extractedText,
        filePath: copiedFilePath,
        documentType: type,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Import failed: $e',
        documentType: type,
      );
    }
  }

  /// Cache extracted document with specific scope
  Future<int> cacheDocumentWithScope({
    required String fileName,
    required String filePath,
    required String extractedText,
    required DocumentScope scope,
    Map<String, dynamic>? scopeDetails,
    int? totalPages,
  }) async {
    return await _cacheService.cacheDocument(
      fileName: fileName,
      filePath: filePath,
      extractedText: extractedText,
      selectedScope: scope.name,
      scopeDetails: scopeDetails,
      totalPages: totalPages,
    );
  }

  /// Get cached document by ID
  Future<ImportResult?> getCachedDocument(int id) async {
    try {
      final doc = await _cacheService.getCachedDocument(id);
      if (doc == null) return null;

      return ImportResult(
        success: true,
        extractedText: doc.extractedText,
        filePath: doc.filePath,
        documentType: _detectDocumentTypeFromPath(doc.filePath),
        totalPages: doc.totalPages,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Failed to load cached document: $e',
        documentType: DocumentType.txt,
      );
    }
  }

  /// Get all cached documents
  Future<List<ImportResult>> getAllCachedDocuments() async {
    try {
      final docs = await _cacheService.getAllCachedDocuments();
      return docs.map((doc) => ImportResult(
        id: doc.id,
        success: true,
        extractedText: doc.extractedText,
        filePath: doc.filePath,
        documentType: _detectDocumentTypeFromPath(doc.filePath),
        totalPages: doc.totalPages,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete cached document
  Future<bool> deleteCachedDocument(int id) async {
    try {
      final doc = await _cacheService.getCachedDocument(id);
      if (doc != null) {
        // Delete from cache
        await _cacheService.deleteCachedDocument(id);
        // Delete from app storage
        await _fileManagementService.deleteFileFromAppStorage(doc.filePath);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Private helper methods

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        // User should be guided to settings in the UI
        return false;
      }
      return false;
    }
    return true;
  }

  Future<FilePickerResult?> _pickFile() async {
    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx'],
    );
  }

  Future<FilePickerResult?> _pickFileOfType(DocumentType type) async {
    String extension;
    switch (type) {
      case DocumentType.pdf:
        extension = 'pdf';
        break;
      case DocumentType.txt:
        extension = 'txt';
        break;
      case DocumentType.docx:
        extension = 'docx';
        break;
    }

    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [extension],
    );
  }

  DocumentType _detectDocumentType(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return DocumentType.pdf;
      case 'txt':
        return DocumentType.txt;
      case 'docx':
        return DocumentType.docx;
      default:
        return DocumentType.txt;
    }
  }

  DocumentType _detectDocumentTypeFromPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return DocumentType.pdf;
      case 'txt':
        return DocumentType.txt;
      case 'docx':
        return DocumentType.docx;
      default:
        return DocumentType.txt;
    }
  }
}