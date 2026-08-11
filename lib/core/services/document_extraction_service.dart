import 'dart:io';

class DocumentExtractionService {
  /// Extract text from a PDF file
  static Future<String> extractFromPdf(File file, {List<int>? pages}) async {
    try {
      // For now, PDF text extraction is not implemented
      // This would require a dedicated PDF text extraction library
      // Returning a placeholder message
      if (pages != null && pages.isNotEmpty) {
        return 'PDF text extraction is not yet implemented. '
               'Selected pages: ${pages.join(", ")}. '
               'Please use TXT files for now.';
      }
      return 'PDF text extraction is not yet implemented. '
             'Please use TXT files for now.';
    } catch (e) {
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  /// Extract text from a TXT file
  static Future<String> extractFromTxt(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      throw Exception('Failed to extract text from TXT: $e');
    }
  }

  /// Extract text from a DOCX file
  static Future<String> extractFromDocx(File file) async {
    try {
      // DOCX extraction requires additional libraries
      // For now, throw an exception indicating this feature is not yet implemented
      throw UnimplementedError('DOCX extraction is not yet implemented. Please use PDF or TXT files.');
    } catch (e) {
      throw Exception('Failed to extract text from DOCX: $e');
    }
  }

  /// Extract text based on file type
  static Future<String> extractFromFile(File file, {List<int>? pages}) async {
    final extension = file.path.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return extractFromPdf(file, pages: pages);
      case 'txt':
        return extractFromTxt(file);
      case 'docx':
        return extractFromDocx(file);
      default:
        throw Exception('Unsupported file type: $extension');
    }
  }

  /// Clean and normalize extracted text
  static String cleanText(String text) {
    // Remove excessive whitespace
    String cleaned = text.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove page break markers if needed
    cleaned = cleaned.replaceAll('--- Page Break ---', '\n\n');
    
    // Remove special characters that might interfere with AI processing
    cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    
    return cleaned.trim();
  }

  /// Get basic statistics about the text
  static Map<String, int> getTextStatistics(String text) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final sentences = text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).length;
    final characters = text.length;
    final paragraphs = text.split(RegExp(r'\n\n+')).where((p) => p.trim().isNotEmpty).length;
    
    return {
      'words': words,
      'sentences': sentences,
      'characters': characters,
      'paragraphs': paragraphs,
    };
  }

  /// Truncate text to a maximum length while preserving sentence boundaries
  static String truncateText(String text, {int maxLength = 10000}) {
    if (text.length <= maxLength) return text;
    
    // Find the last sentence boundary before the limit
    final truncated = text.substring(0, maxLength);
    final lastSentenceEnd = truncated.lastIndexOf(RegExp(r'[.!?]'));
    
    if (lastSentenceEnd > maxLength * 0.8) {
      return truncated.substring(0, lastSentenceEnd + 1);
    }
    
    return truncated;
  }
}