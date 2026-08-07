import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocumentExtractionService {
  /// Extract text from a PDF file
  static Future<String> extractFromPdf(File file, {List<int>? pages}) async {
    try {
      final bytes = await file.readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      
      if (pages == null || pages.isEmpty) {
        // Extract all pages
        final allText = <String>[];
        for (int i = 0; i < doc.pages.count; i++) {
          final textExtractor = PdfTextExtractor(doc);
          final text = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
          allText.add(text);
        }
        doc.dispose();
        return allText.join('\n\n--- Page Break ---\n\n');
      } else {
        // Extract specific pages
        final selectedText = <String>[];
        for (final pageNumber in pages..sort()) {
          final pageIndex = pageNumber - 1; // Convert to 0-based index
          if (pageIndex >= 0 && pageIndex < doc.pages.count) {
            final textExtractor = PdfTextExtractor(doc);
            final text = textExtractor.extractText(startPageIndex: pageIndex, endPageIndex: pageIndex);
            selectedText.add(text);
          }
        }
        doc.dispose();
        return selectedText.join('\n\n--- Page Break ---\n\n');
      }
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

  /// Extract text based on file type
  static Future<String> extractFromFile(File file, {List<int>? pages}) async {
    final extension = file.path.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return extractFromPdf(file, pages: pages);
      case 'txt':
        return extractFromTxt(file);
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