import 'imported_text_reconstructor.dart';

/// Shared cleaning contract used by all source-specific cleaners.
abstract class UnifiedTextCleaner {
  /// The canonical cleaning entry point.
  ///
  /// [rawText] is the extracted text, [sourceHint] is optional (pdf, docx,
  /// txt, ocr) so the implementation can apply source-specific adjustments.
  static String clean(String rawText, {String? sourceHint}) {
    return _allSourcesClean(rawText, sourceHint: sourceHint ?? 'unknown');
  }

  /// Source-agnostic reconstruction: paragraphs, vertical letters, broken
  /// words, and whitespace normalization.
  static String _allSourcesClean(String rawText, {String sourceHint = 'unknown'}) {
    // 1. Normalize line endings.
    String text = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();

    // 2. Reconstruct paragraphs/vertical text/broken words.
    if (sourceHint == 'pdf') {
      text = _pdfReconstruct(text);
    } else {
      text = ImportedTextReconstructor.reconstruct(text);
    }

    // 3. Source-specific extra passes.
    switch (sourceHint) {
      case 'docx':
        text = _docxExtraClean(text);
      case 'txt':
        text = _txtExtraClean(text);
      case 'ocr':
        text = _ocrExtraClean(text);
      case 'pdf':
      default:
        break;
    }

    // 4. Final whitespace and punctuation normalization.
    text = _normalizePunctuation(text);
    text = text.replaceAllMapped(RegExp(r'[ \t]+'), (_) => ' ');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  /// DOCX-specific: remove leftover non-printing control ranges and
  /// duplicate header/footer-like short lines.
  static String _docxExtraClean(String text) {
    text = text.replaceAllMapped(
      RegExp(r'(\n|^)(\s*[^\w\s]{2,}\s*)(\n|$)', multiLine: true),
      (m) => '\n',
    );
    return text;
  }

  /// TXT-specific: fix wrapped paragraphs and remove spurious blank lines
  /// introduced by fixed-width text files.
  static String _txtExtraClean(String text) {
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z,;:])(\n)([a-z])', multiLine: true),
      (m) => '${m.group(1)} ${m.group(3)}',
    );
    return text;
  }

  /// OCR-specific: remove isolated single-character noise lines while
  /// preserving blank lines (paragraph breaks), list markers, and headings.
  static String _ocrExtraClean(String text) {
    final lines = text.split('\n');
    final kept = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      // Preserve blank lines so paragraph breaks survive.
      if (trimmed.isEmpty) {
        kept.add('');
        continue;
      }
      // Preserve list markers and short numeric/letter list labels.
      if (RegExp(r'^(\d+[).\-]\s+|[-*•]\s+)').hasMatch(trimmed)) {
        kept.add(line);
        continue;
      }
      // Drop lines that are only one or two non-word symbols (OCR noise).
      if (trimmed.length <= 2 && !RegExp(r'^[A-Za-z0-9]{1,2}$').hasMatch(trimmed)) {
        continue;
      }
      kept.add(line);
    }
    // Collapse runs of blank lines beyond a single paragraph break.
    return kept.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  static String _normalizePunctuation(String text) {
    // Ensure proper spacing after sentence-ending punctuation.
    return text
        .replaceAllMapped(
          RegExp(r'([.!?])([A-Z])'),
          (m) => '${m.group(1)} ${m.group(2)}',
        )
        .replaceAllMapped(
          RegExp(r'([:,;])([A-Za-z])'),
          (m) => '${m.group(1)} ${m.group(2)}',
        );
  }

  /// PDF-specific reconstruction that preserves the physical layout from the
  /// extractor while joining wrapped lines, removing line-wrap hyphens, and
  /// keeping paragraph/heading boundaries.
  static String _pdfReconstruct(String rawText) {
    // 1. Normalize line endings.
    String text = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();

    // 2. Remove line-wrap hyphens (e.g., "sen-\ntence" -> "sentence").
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z]{2,})-\n([a-zA-Z]{2,})'),
      (m) {
        final before = m.group(1)!;
        final after = m.group(2)!;
        final combined = '$before$after';
        if (combined.length < 30 && RegExp(r'[aeiouAEIOU]').hasMatch(combined)) {
          return combined;
        }
        return '$before-$after';
      },
    );

    // 3. Reconstruct wrapped paragraphs.
    final lines = text.split('\n');
    final paragraphs = <String>[];
    final current = StringBuffer();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].replaceAll(RegExp(r'[ \t]+'), ' ').trimRight();
      if (line.isEmpty) {
        if (current.isNotEmpty) {
          paragraphs.add(current.toString().trim());
          current.clear();
        }
        paragraphs.add('');
        continue;
      }

      final isLast = i == lines.length - 1;
      final next = isLast ? null : lines[i + 1].replaceAll(RegExp(r'[ \t]+'), ' ').trimRight();
      final shouldJoin = !isLast &&
          next != null &&
          next.isNotEmpty &&
          _shouldJoinPdfLines(line, next);

      if (current.isNotEmpty) {
        if (shouldJoin) {
          current.write(' ');
        } else {
          paragraphs.add(current.toString().trim());
          current.clear();
        }
      }
      current.write(line);
    }

    if (current.isNotEmpty) {
      paragraphs.add(current.toString().trim());
    }

    text = paragraphs.join('\n');

    // 4. Collapse 3+ consecutive line breaks to a paragraph break.
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  static bool _shouldJoinPdfLines(String current, String next) {
    final trimmedCurrent = current.trim();
    final trimmedNext = next.trim();

    if (trimmedCurrent.isEmpty || trimmedNext.isEmpty) return false;

    // Never join headings or list items with the following/previous line.
    if (_isPdfHeadingLine(trimmedCurrent) || _isPdfListLine(trimmedCurrent)) return false;
    if (_isPdfHeadingLine(trimmedNext) || _isPdfListLine(trimmedNext)) return false;

    // End of a sentence is the end of a paragraph.
    if (RegExp(r'[.!?]$').hasMatch(trimmedCurrent)) return false;

    final last = trimmedCurrent[trimmedCurrent.length - 1];
    final first = trimmedNext[0];

    // Continue a sentence that is broken at punctuation.
    if (last == ',' || last == ';' || last == ':') {
      return true;
    }

    // Continue when the current line is open and the next starts with a
    // lowercase word (likely the same wrapped paragraph).
    final currentOpen = last.toLowerCase() == last;
    final nextContinues = first.toLowerCase() == first;
    return currentOpen && nextContinues;
  }

  static bool _isPdfHeadingLine(String line) {
    return RegExp(r'^(Chapter|Section|Topic|Unit|Lesson|Module)\s+\d+', caseSensitive: false).hasMatch(line) ||
        RegExp(r'^(\d+\.[\d.]*\s+)').hasMatch(line) ||
        (line == line.toUpperCase() && line.contains(RegExp(r'[A-Z]')));
  }

  static bool _isPdfListLine(String line) {
    return RegExp(r'^(\d+[).-]\s+|[-*•]\s+)').hasMatch(line);
  }
}

/// Cleaner tuned for DOCX extracted XML text.
class DocxTextCleaner {
  static String clean(String rawText) => UnifiedTextCleaner._allSourcesClean(rawText, sourceHint: 'docx');
}

/// Cleaner tuned for plain TXT files.
class TxtTextCleaner {
  static String clean(String rawText) => UnifiedTextCleaner._allSourcesClean(rawText, sourceHint: 'txt');
}

/// Cleaner tuned for camera/OCR text.
class OcrTextCleaner {
  static String clean(String rawText) => UnifiedTextCleaner._allSourcesClean(rawText, sourceHint: 'ocr');
}
