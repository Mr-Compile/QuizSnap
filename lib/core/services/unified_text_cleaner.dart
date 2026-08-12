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
    text = ImportedTextReconstructor.reconstruct(text);

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

  /// OCR-specific: aggressively remove isolated single characters and
  /// common noise fragments.
  static String _ocrExtraClean(String text) {
    final lines = text.split('\n');
    final kept = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Drop lines that are only one or two non-word symbols.
      if (trimmed.length <= 2 && !RegExp(r'^[A-Za-z0-9]{1,2}$').hasMatch(trimmed)) {
        continue;
      }
      kept.add(line);
    }
    return kept.join('\n');
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
