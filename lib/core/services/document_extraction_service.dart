import 'dart:io';
import 'dart:convert';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'text_normalization_service.dart';
import 'unified_text_cleaner.dart';

class DocumentExtractionService {
  /// Returns the total number of pages in a PDF without rendering.
  static Future<int> getPageCount(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final count = document.pages.count;
      document.dispose();
      return count;
    } catch (e) {
      throw Exception('Failed to determine PDF page count: $e');
    }
  }

  /// Extract text from a PDF file
  static Future<String> extractFromPdf(File file, {List<int>? pages}) async {
    try {
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor textExtractor = PdfTextExtractor(document);

      final String extractedText;
      if (pages != null && pages.isNotEmpty) {
        final sortedPages = pages.toSet().toList()..sort();
        final buffer = StringBuffer();
        for (final page in sortedPages) {
          if (page >= 1 && page <= document.pages.count) {
            buffer.writeln(
              textExtractor.extractText(
                startPageIndex: page - 1,
                endPageIndex: page - 1,
                layoutText: true,
              ),
            );
          }
        }
        extractedText = buffer.toString();
      } else {
        extractedText = textExtractor.extractText();
      }

      document.dispose();

      if (extractedText.trim().isEmpty) {
        throw Exception('No text could be extracted from PDF');
      }

      final normalized = TextNormalizationService.reconstruct(extractedText);
      return normalized;
    } catch (e) {
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  /// Extract text from a TXT file, preserving UTF-8 encoding and line breaks.
  static Future<String> extractFromTxt(File file) async {
    try {
      final content = await file.readAsString(encoding: utf8);
      // Normalize line endings, then run the TXT-specific cleaner.
      return TxtTextCleaner.clean(
        content.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
      );
    } catch (e) {
      throw Exception('Failed to extract text from TXT: $e');
    }
  }

  /// Extract text from a DOCX file
  static Future<String> extractFromDocx(File file) async {
    try {
      // DOCX files are ZIP archives containing XML files
      // The main content is in word/document.xml
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Find the document.xml file
      ArchiveFile? documentFile;
      for (final file in archive.files) {
        if (file.name == 'word/document.xml' || file.name.endsWith('word/document.xml')) {
          documentFile = file;
          break;
        }
      }
      
      if (documentFile == null) {
        throw Exception('Could not find document.xml in DOCX file');
      }
      
      // Extract and decode the XML content
      final content = documentFile.content as List<int>;
      final xmlString = utf8.decode(content);
      
      // Extract text from XML - remove all tags and decode HTML entities
      String extractedText = _extractTextFromXml(xmlString);
      
      // Clean up the extracted text and reconstruct readable paragraphs.
      extractedText = _cleanDocxText(extractedText);
      final normalized = DocxTextCleaner.clean(extractedText);

      if (normalized.trim().isEmpty) {
        throw Exception('No text could be extracted from DOCX');
      }

      return normalized;
    } catch (e) {
      throw Exception('Failed to extract text from DOCX: $e');
    }
  }
  
  /// Extract text content from XML by removing tags while preserving the
  /// document's paragraph and line-break structure.
  ///
  /// DOCX represents paragraphs with `<w:p>` and explicit line breaks with
  /// `<w:br/>` / `<w:cr/>`; tabs use `<w:tab/>`. We convert these structural
  /// markers to newlines/tabs *before* stripping the remaining tags so the
  /// downstream cleaner and review screens can preserve paragraph breaks,
  /// blank lines, lists, headings, and indentation instead of collapsing
  /// everything into a single space-separated line.
  static String _extractTextFromXml(String xml) {
    String text = xml;

    // Preserve structural markers as real whitespace before tag stripping.
    // Each paragraph end -> newline; an extra blank line between paragraphs
    // is introduced by the closing tag so consecutive paragraphs are
    // separated by a paragraph break (\n\n) after normalization.
    text = text.replaceAllMapped(
      RegExp(r'</w:p>', caseSensitive: false),
      (_) => '\n\n',
    );
    text = text.replaceAllMapped(
      RegExp(r'<w:br\s*/?>', caseSensitive: false),
      (_) => '\n',
    );
    text = text.replaceAllMapped(
      RegExp(r'<w:cr\s*/?>', caseSensitive: false),
      (_) => '\n',
    );
    text = text.replaceAllMapped(
      RegExp(r'<w:tab\s*/?>', caseSensitive: false),
      (_) => '\t',
    );

    // Remove all remaining XML tags.
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // Decode common HTML entities.
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&apos;', "'");
    text = text.replaceAll('&nbsp;', ' ');

    return text;
  }

  /// Clean DOCX extracted text while preserving paragraph breaks, blank lines,
  /// list markers, headings, and indentation.
  ///
  /// Only spaces/tabs are collapsed (never newlines), and runs of more than
  /// two newlines are reduced to a single paragraph break. This keeps the
  /// document human-readable in review screens and AI prompts.
  static String _cleanDocxText(String text) {
    // Normalize line endings.
    String cleaned = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Collapse runs of spaces/tabs into a single space, but preserve newlines.
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');

    // Trim trailing whitespace on each line (keeps indentation via leading
    // spaces being already collapsed above; we only strip trailing noise).
    cleaned = cleaned.split('\n').map((l) => l.trimRight()).join('\n');

    // Collapse 3+ newlines into a single paragraph break (\n\n).
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Remove control characters that interfere with processing, but keep
    // newlines (\n) and tabs (\t).
    cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

    return cleaned.trim();
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

  /// Clean and normalize extracted text while preserving paragraph structure.
  static String cleanText(String text) {
    return TextNormalizationService.reconstruct(text);
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

  /// Extract text from image using OCR (for camera capture)
  static Future<String> extractFromImage(String imagePath) async {
    try {
      // This would be called from the camera OCR screen
      // The actual OCR processing is done in camera_ocr_screen.dart
      // This is a placeholder for the service interface
      throw Exception('OCR processing should be done in camera_ocr_screen.dart');
    } catch (e) {
      throw Exception('Failed to extract text from image: $e');
    }
  }
}