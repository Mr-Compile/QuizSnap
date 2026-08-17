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
        extractedText = textExtractor.extractText(
          startPageIndex: 0,
          endPageIndex: document.pages.count - 1,
          layoutText: true,
        );
      }

      document.dispose();

      if (extractedText.trim().isEmpty) {
        throw Exception('No text could be extracted from PDF');
      }

      final normalized = UnifiedTextCleaner.clean(extractedText, sourceHint: 'pdf');
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
  static Future<String> extractFromDocx(File file, {List<int>? pages}) async {
    try {
      final allPages = await extractDocxPages(file);

      if (allPages.isEmpty) {
        throw Exception('No text could be extracted from DOCX');
      }

      final selected = (pages == null || pages.isEmpty)
          ? List.generate(allPages.length, (i) => i + 1)
          : pages.where((p) => p >= 1 && p <= allPages.length).toSet().toList()..sort();

      final buffer = StringBuffer();
      for (final page in selected) {
        if (buffer.isNotEmpty) buffer.write('\n\n');
        buffer.write(allPages[page - 1]);
      }

      final result = buffer.toString().trim();
      if (result.isEmpty) {
        throw Exception('No text could be extracted from DOCX');
      }

      return result;
    } catch (e) {
      throw Exception('Failed to extract text from DOCX: $e');
    }
  }

  /// Returns the number of DOCX pages/segments determined from explicit page
  /// breaks in the document or a deterministic chunk size fallback.
  static Future<int> getDocxPageCount(File file) async {
    final pages = await extractDocxPages(file);
    return pages.length;
  }

  /// Extracts DOCX content as a list of page/segment strings.
  static Future<List<String>> extractDocxPages(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

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

    final content = documentFile.content as List<int>;
    final xmlString = utf8.decode(content);
    String raw = _extractTextFromXml(xmlString);

    // DOCX often has no real page breaks. Keep the raw form-feed markers for
    // explicit breaks, then segment deterministically if none are present.
    final parts = raw.split('\f');
    final pages = <String>[];
    for (final part in parts) {
      if (part.trim().isEmpty) continue;
      final cleaned = DocxTextCleaner.clean(part);
      if (cleaned.trim().isNotEmpty) {
        pages.add(cleaned.trim());
      }
    }

    if (pages.isEmpty) return const [];

    // If the document has no explicit page breaks, split the content into
    // page-like chunks at paragraph boundaries so the user can still select
    // specific portions of a long document.
    const targetChars = 2000;
    if (pages.length == 1 && pages.first.length > targetChars) {
      return _splitDocxTextIntoChunks(pages.first, targetChars);
    }

    return pages;
  }

  /// Splits a long DOCX text into page-like chunks at paragraph boundaries.
  static List<String> _splitDocxTextIntoChunks(String text, int targetChars) {
    final paragraphs = text.split('\n\n');
    final chunks = <String>[];
    final current = StringBuffer();

    for (final paragraph in paragraphs) {
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) continue;

      if (current.isNotEmpty && current.length + trimmed.length + 2 > targetChars) {
        chunks.add(current.toString().trim());
        current.clear();
      }

      if (current.isNotEmpty) current.write('\n\n');
      current.write(trimmed);
    }

    if (current.isNotEmpty) {
      chunks.add(current.toString().trim());
    }

    return chunks.isEmpty ? [text.trim()] : chunks;
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
    // Preserve explicit DOCX page breaks so consumers can split by real pages
    // or fall back to a deterministic segmentation.
    text = text.replaceAllMapped(
      RegExp(r'<w:lastRenderedPageBreak\s*/?>', caseSensitive: false),
      (_) => '\f',
    );
    text = text.replaceAllMapped(
      RegExp(r'''<w:br[^>]*?\btype=["\']page["\'][^>]*?/?>''', caseSensitive: false),
      (_) => '\f',
    );
    text = text.replaceAllMapped(
      RegExp(r'''(<w:p[^>]*?\bpageBreakBefore\s*=\s*["\']1["\'][^>]*>)''', caseSensitive: false),
      (m) => '\f${m.group(1)}',
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

  /// Extract text based on file type
  static Future<String> extractFromFile(File file, {List<int>? pages}) async {
    final extension = file.path.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return extractFromPdf(file, pages: pages);
      case 'txt':
        return extractFromTxt(file);
      case 'docx':
        return extractFromDocx(file, pages: pages);
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