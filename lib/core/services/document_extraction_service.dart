import 'dart:io';
import 'dart:convert';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive.dart';

class DocumentExtractionService {
  /// Extract text from a PDF file
  static Future<String> extractFromPdf(File file, {List<int>? pages}) async {
    try {
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      // Extract text from the entire document
      final PdfTextExtractor textExtractor = PdfTextExtractor(document);
      final extractedText = textExtractor.extractText();
      
      document.dispose();
      
      if (extractedText.trim().isEmpty) {
        throw Exception('No text could be extracted from PDF');
      }
      
      return extractedText.trim();
    } catch (e) {
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  /// Extract text from a TXT file, preserving UTF-8 encoding and line breaks.
  static Future<String> extractFromTxt(File file) async {
    try {
      final content = await file.readAsString(encoding: utf8);
      // Normalize line endings but keep paragraph breaks.
      return content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
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
      
      // Clean up the extracted text
      extractedText = _cleanDocxText(extractedText);
      
      if (extractedText.trim().isEmpty) {
        throw Exception('No text could be extracted from DOCX');
      }
      
      return extractedText;
    } catch (e) {
      throw Exception('Failed to extract text from DOCX: $e');
    }
  }
  
  /// Extract text content from XML by removing tags
  static String _extractTextFromXml(String xml) {
    // Remove all XML tags
    String text = xml.replaceAll(RegExp(r'<[^>]*>'), ' ');
    
    // Decode common HTML entities
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&apos;', "'");
    text = text.replaceAll('&nbsp;', ' ');
    
    return text;
  }
  
  /// Clean DOCX extracted text
  static String _cleanDocxText(String text) {
    // Remove excessive whitespace
    String cleaned = text.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove special characters that might interfere with AI processing
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
    // Normalize line endings
    String cleaned = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Remove page break markers and replace with paragraph breaks
    cleaned = cleaned.replaceAll('--- Page Break ---', '\n\n');

    // Collapse multiple consecutive spaces into a single space, but keep newlines.
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'[ \t]+'),
      (match) => ' ',
    );

    // Preserve double newlines (paragraphs) but collapse more than two.
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Remove special control characters except newlines and tabs
    cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

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