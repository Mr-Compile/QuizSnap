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
  static Future<String> extractFromTxt(File file, {List<int>? pages}) async {
    try {
      final allPages = await extractTxtPages(file);

      if (allPages.isEmpty) {
        throw Exception('No text could be extracted from TXT');
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
        throw Exception('No text could be extracted from TXT');
      }

      return result;
    } catch (e) {
      throw Exception('Failed to extract text from TXT: $e');
    }
  }

  /// Returns the number of logical TXT pages/segments.
  static Future<int> getTxtPageCount(File file) async {
    final pages = await extractTxtPages(file);
    return pages.length;
  }

  /// Extracts a TXT file as a list of logical page/segment strings.
  static Future<List<String>> extractTxtPages(File file) async {
    final content = await file.readAsString(encoding: utf8);
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final cleaned = TxtTextCleaner.clean(normalized);

    if (cleaned.trim().isEmpty) {
      return const [];
    }

    // Split into paragraphs and group them into logical pages.
    final paragraphs = cleaned.split(RegExp(r'\n{2,}'));
    const targetChars = 2000;
    return _groupParagraphsIntoPages(paragraphs, targetChars);
  }

  static List<String> _groupParagraphsIntoPages(List<String> paragraphs, int targetChars) {
    final pages = <String>[];
    final current = StringBuffer();

    for (final raw in paragraphs) {
      final paragraph = raw.trim();
      if (paragraph.isEmpty) continue;

      final chunks = _splitLargeParagraph(paragraph, targetChars);
      for (final chunk in chunks) {
        if (current.isNotEmpty && current.length + 2 + chunk.length > targetChars) {
          pages.add(current.toString().trim());
          current.clear();
        }
        if (current.isNotEmpty) current.write('\n\n');
        current.write(chunk);
      }
    }

    if (current.isNotEmpty) {
      pages.add(current.toString().trim());
    }

    return pages;
  }

  /// Splits a single large paragraph at a sentence or word boundary.
  static List<String> _splitLargeParagraph(String paragraph, int targetChars) {
    if (paragraph.length <= targetChars) {
      return [paragraph];
    }

    final chunks = <String>[];
    var start = 0;

    while (start < paragraph.length) {
      if (paragraph.length - start <= targetChars) {
        chunks.add(paragraph.substring(start).trim());
        break;
      }

      var end = start + targetChars;
      var bestEnd = end;

      // Prefer breaking at a sentence end.
      for (var i = end; i > start + targetChars ~/ 2; i--) {
        if (i < paragraph.length - 1 &&
            RegExp(r'[.!?]').hasMatch(paragraph[i]) &&
            paragraph[i + 1] == ' ') {
          bestEnd = i + 1;
          break;
        }
      }

      if (bestEnd == end) {
        // Fall back to the nearest word boundary.
        final space = paragraph.lastIndexOf(' ', end);
        if (space > start) {
          bestEnd = space;
        }
      }

      chunks.add(paragraph.substring(start, bestEnd).trim());
      start = bestEnd;

      while (start < paragraph.length && paragraph[start] == ' ') {
        start++;
      }
    }

    return chunks;
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

  // ─── PPTX (Office Open XML) ───────────────────────────────────────────

  /// Extract text from a PPTX file, preserving slide structure.
  static Future<String> extractFromPptx(File file, {List<int>? pages}) async {
    try {
      final allSlides = await extractPptxSlides(file);

      if (allSlides.isEmpty) {
        throw Exception('No text could be extracted from PPTX');
      }

      final selected = (pages == null || pages.isEmpty)
          ? List.generate(allSlides.length, (i) => i + 1)
          : pages.where((p) => p >= 1 && p <= allSlides.length).toSet().toList()..sort();

      final buffer = StringBuffer();
      for (final slide in selected) {
        if (buffer.isNotEmpty) buffer.write('\n\n');
        buffer.write(allSlides[slide - 1]);
      }

      final result = buffer.toString().trim();
      if (result.isEmpty) {
        throw Exception('No text could be extracted from PPTX');
      }

      return result;
    } catch (e) {
      throw Exception('Failed to extract text from PPTX: $e');
    }
  }

  /// Returns the number of slides in a PPTX file.
  static Future<int> getPptxSlideCount(File file) async {
    final slides = await extractPptxSlides(file);
    return slides.length;
  }

  /// Extracts PPTX content as a list of slide strings, preserving order.
  static Future<List<String>> extractPptxSlides(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Collect all slide XML files and sort by slide number.
    final slideFiles = <_PptxSlideFile>[];
    for (final entry in archive.files) {
      final match = RegExp(r'^ppt/slides/slide(\d+)\.xml$').firstMatch(entry.name);
      if (match != null) {
        slideFiles.add(_PptxSlideFile(
          number: int.parse(match.group(1)!),
          name: entry.name,
          content: entry.content as List<int>,
        ));
      }
    }

    if (slideFiles.isEmpty) {
      throw Exception('No slides found in PPTX file');
    }

    slideFiles.sort((a, b) => a.number.compareTo(b.number));

    final slides = <String>[];
    for (final slideFile in slideFiles) {
      final xmlString = utf8.decode(slideFile.content);
      final text = _extractTextFromPptxSlideXml(xmlString);
      final cleaned = UnifiedTextCleaner.clean(text, sourceHint: 'pptx');
      if (cleaned.trim().isNotEmpty) {
        slides.add(cleaned.trim());
      } else {
        // Keep empty slides so numbering stays consistent.
        slides.add('');
      }
    }

    return slides;
  }

  /// Extracts text from a single PPTX slide XML, preserving paragraphs and
  /// line breaks. PPTX uses `<a:p>` for paragraphs and `<a:t>` for text runs.
  static String _extractTextFromPptxSlideXml(String xml) {
    String text = xml;

    // Convert paragraph ends to double newlines.
    text = text.replaceAllMapped(
      RegExp(r'</a:p>', caseSensitive: false),
      (_) => '\n\n',
    );
    // Convert line breaks to single newlines.
    text = text.replaceAllMapped(
      RegExp(r'<a:br\s*/?>', caseSensitive: false),
      (_) => '\n',
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
    // Collapse multiple spaces but preserve newlines.
    text = text.replaceAllMapped(
      RegExp(r'[ \t]+'),
      (_) => ' ',
    );
    return text.trim();
  }

  // ─── PPT (Legacy Binary) ──────────────────────────────────────────────

  /// Extract text from a legacy PPT file using binary UTF-16LE scanning.
  static Future<String> extractFromPpt(File file, {List<int>? pages}) async {
    try {
      final allSlides = await extractPptSlides(file);

      if (allSlides.isEmpty) {
        throw Exception('No text could be extracted from PPT');
      }

      final selected = (pages == null || pages.isEmpty)
          ? List.generate(allSlides.length, (i) => i + 1)
          : pages.where((p) => p >= 1 && p <= allSlides.length).toSet().toList()..sort();

      final buffer = StringBuffer();
      for (final slide in selected) {
        if (buffer.isNotEmpty) buffer.write('\n\n');
        buffer.write(allSlides[slide - 1]);
      }

      final result = buffer.toString().trim();
      if (result.isEmpty) {
        throw Exception('No text could be extracted from PPT');
      }

      return result;
    } catch (e) {
      throw Exception('Failed to extract text from PPT: $e');
    }
  }

  /// Returns the number of slides detected in a PPT file.
  static Future<int> getPptSlideCount(File file) async {
    final slides = await extractPptSlides(file);
    return slides.length;
  }

  /// Extracts text from a legacy PPT binary file.
  ///
  /// PPT stores text as UTF-16LE in "TextBytesAtom" (record type 0x0FA0) and
  /// "TextCharsAtom" (record type 0x2000) records. We scan the binary stream
  /// for these records and extract the text, splitting on slide boundaries
  /// (SlidePersistAtom, record type 0x03F3).
  static Future<List<String>> extractPptSlides(File file) async {
    final bytes = await file.readAsBytes();

    if (bytes.length < 8) {
      throw Exception('PPT file is too small or corrupted');
    }

    final slides = <String>[];
    final currentText = StringBuffer();

    // Walk through the PPT record stream. Each record has:
    // - 2 bytes: version (low byte = recVer, high byte = recInstance)
    // - 2 bytes: type
    // - 4 bytes: length (LE)
    // - [length] bytes: data
    int offset = 0;
    final data = bytes;

    while (offset + 8 <= data.length) {
      final type = _readUint16LE(data, offset + 2);
      final length = _readUint32LE(data, offset + 4);

      if (length < 0 || offset + 8 + length > data.length) {
        break;
      }

      final recordData = data.sublist(offset + 8, offset + 8 + length);

      switch (type) {
        case 0x03F3: // SlidePersistAtom — marks a new slide
          if (currentText.toString().trim().isNotEmpty) {
            final cleaned = UnifiedTextCleaner.clean(currentText.toString(), sourceHint: 'pptx');
            slides.add(cleaned.trim());
            currentText.clear();
          }
          break;
        case 0x0FA0: // TextBytesAtom — ASCII/Latin-1 text
          if (currentText.isNotEmpty) currentText.write('\n');
          currentText.write(String.fromCharCodes(recordData));
          break;
        case 0x2000: // TextCharsAtom — UTF-16LE text
          if (currentText.isNotEmpty) currentText.write('\n');
          currentText.write(_decodeUtf16LE(recordData));
          break;
        default:
          break;
      }

      offset += 8 + length;
    }

    // Flush the last slide's text.
    if (currentText.toString().trim().isNotEmpty) {
      final cleaned = UnifiedTextCleaner.clean(currentText.toString(), sourceHint: 'pptx');
      slides.add(cleaned.trim());
    }

    if (slides.isEmpty) {
      // Fallback: scan for any readable UTF-16LE text sequences.
      final fallback = _extractPptFallbackText(bytes);
      if (fallback.isNotEmpty) {
        return [fallback];
      }
      throw Exception('No text could be extracted from PPT');
    }

    return slides;
  }

  static int _readUint16LE(List<int> data, int offset) {
    return data[offset] | (data[offset + 1] << 8);
  }

  static int _readUint32LE(List<int> data, int offset) {
    return data[offset] |
        (data[offset + 1] << 8) |
        (data[offset + 2] << 16) |
        (data[offset + 3] << 24);
  }

  static String _decodeUtf16LE(List<int> data) {
    final codeUnits = <int>[];
    for (var i = 0; i + 1 < data.length; i += 2) {
      codeUnits.add(data[i] | (data[i + 1] << 8));
    }
    return String.fromCharCodes(codeUnits);
  }

  /// Fallback: scan for UTF-16LE text runs in the binary when structured
  /// record parsing yields nothing.
  static String _extractPptFallbackText(List<int> bytes) {
    final buffer = StringBuffer();
    var i = 0;
    while (i + 1 < bytes.length) {
      // Look for runs of printable UTF-16LE characters.
      if (bytes[i] >= 0x20 && bytes[i] < 0x7F && bytes[i + 1] == 0) {
        final run = StringBuffer();
        while (i + 1 < bytes.length &&
            bytes[i] >= 0x20 &&
            bytes[i] < 0x7F &&
            bytes[i + 1] == 0) {
          run.write(String.fromCharCode(bytes[i]));
          i += 2;
        }
        final text = run.toString().trim();
        if (text.length >= 3) {
          if (buffer.isNotEmpty) buffer.write('\n');
          buffer.write(text);
        }
      } else {
        i++;
      }
    }
    return buffer.toString().trim();
  }

  /// Extract text based on file type
  static Future<String> extractFromFile(File file, {List<int>? pages}) async {
    final extension = file.path.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return extractFromPdf(file, pages: pages);
      case 'txt':
        return extractFromTxt(file, pages: pages);
      case 'docx':
        return extractFromDocx(file, pages: pages);
      case 'pptx':
        return extractFromPptx(file, pages: pages);
      case 'ppt':
        return extractFromPpt(file, pages: pages);
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

/// Helper class for sorting PPTX slide XML files by slide number.
class _PptxSlideFile {
  final int number;
  final String name;
  final List<int> content;

  _PptxSlideFile({
    required this.number,
    required this.name,
    required this.content,
  });
}