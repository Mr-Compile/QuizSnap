import 'dart:math';

/// Reconstructs poorly-extracted text (OCR/PDF/DOCX/TXT) into readable
/// paragraphs, merging vertical-letter sequences, broken words, and
/// normalizing whitespace while preserving lists and headings.
class ImportedTextReconstructor {
  /// Maximum average line length threshold used to detect paragraph-wrapped
  /// text vs. intentional one-char-per-line output.
  static const int _wrapLineLength = 6;

  /// Reconstructs [rawText] into readable, left-aligned text.
  static String reconstruct(String rawText) {
    String text = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();

    // 1. Merge vertical letters into words.
    text = _mergeVerticalLetters(text);

    // 2. Join broken words split by a single newline.
    text = _joinBrokenWords(text);

    // 3. Restore paragraph wrappers into sentences.
    text = _restoreParagraphs(text);

    // 4. Preserve numbered/bulleted lists.
    text = _preserveLists(text);

    // 5. Preserve potential headings.
    text = _preserveHeadings(text);

    // 6. Final whitespace cleanup.
    text = _cleanupWhitespace(text);

    return text.trim();
  }

  /// Merges sequences where each line is a single non-whitespace character
  /// (e.g. 'P\nH\nI...') into a single word, then a paragraph.
  static String _mergeVerticalLetters(String text) {
    final lines = text.split('\n');
    final buffer = StringBuffer();
    final currentWord = StringBuffer();
    final currentParagraph = StringBuffer();

    void flushWord() {
      if (currentWord.isNotEmpty) {
        currentParagraph.write(currentWord.toString());
        currentWord.clear();
      }
    }

    void flushParagraph() {
      flushWord();
      if (currentParagraph.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write('\n\n');
        buffer.write(currentParagraph.toString().trim());
        currentParagraph.clear();
      }
    }

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        flushParagraph();
        continue;
      }

      final isSingleChar = line.length == 1 && RegExp(r'^[^\s]$').hasMatch(line);

      if (isSingleChar) {
        // Continue building the vertical word.
        currentWord.write(line);
      } else if (line.length <= 3 && RegExp(r'^[A-Za-z]+$').hasMatch(line)) {
        // Could be a short vertical fragment; keep it with the current word
        // if the previous content was also a fragment, otherwise treat as word.
        if (currentWord.isNotEmpty) {
          currentWord.write(line);
        } else {
          flushWord();
          if (currentParagraph.isNotEmpty) currentParagraph.write(' ');
          currentParagraph.write(line);
        }
      } else {
        // A normal line.
        flushWord();
        if (currentParagraph.isNotEmpty) currentParagraph.write(' ');
        currentParagraph.write(line);
      }
    }

    flushParagraph();
    return buffer.toString();
  }

  /// Joins words that have been split across lines (e.g. 'informa\ntion')
  /// while avoiding intentional paragraph breaks.
  static String _joinBrokenWords(String text) {
    // Only join where the upper line ends with a lowercase letter and the
    // next line starts with a lowercase letter (a simple hyphenation/line-wrap).
    return text.replaceAllMapped(
      RegExp(r'([a-zA-Z]{2,})(\n)([a-zA-Z]{2,})', multiLine: true),
      (match) {
        final before = match.group(1)!;
        final after = match.group(3)!;
        final lowerBefore = before[before.length - 1].toLowerCase();
        final firstAfter = after[0].toLowerCase();

        // If both are lowercase, it's likely a broken word or wrapped paragraph.
        if (lowerBefore == before[before.length - 1] && firstAfter == after[0]) {
          // If the joined word looks plausible, join with no space; otherwise
          // wrap as a single sentence with a space.
          final joined = '$before$after';
          if (_isPlausibleWord(joined)) {
            return joined;
          }
          return '$before $after';
        }
        return match.group(0)!;
      },
    );
  }

  static bool _isPlausibleWord(String word) {
    return word.length < 30 && RegExp(r'[aeiouAEIOU]').allMatches(word).isNotEmpty;
  }

  /// Restarts wrapped paragraphs into sentences.
  static String _restoreParagraphs(String text) {
    final paragraphs = text.split('\n\n');
    final result = <String>[];

    for (final block in paragraphs) {
      final lines = block.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) continue;

      // Detect if this block is a wrapped paragraph (short lines ending
      // without punctuation). We'll join with spaces, then split on sentence
      // endings and rejoin with paragraph breaks.
      final avgLen = lines.fold<int>(0, (sum, l) => sum + l.trim().length) / max(lines.length, 1);
      final mostlyShort = avgLen < _wrapLineLength;
      final endsWithPunctuation = lines.every((l) {
        final trimmed = l.trim();
        return trimmed.endsWith('.') || trimmed.endsWith('!') || trimmed.endsWith('?') || trimmed.endsWith(':') || trimmed.endsWith(';') || trimmed.endsWith(',') || trimmed.length < 4;
      });

      if (mostlyShort && !endsWithPunctuation) {
        final joined = lines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        result.add(_splitIntoSentences(joined));
      } else {
        // Keep as-is but merge single newlines that are not list/heading items.
        final merged = <String>[];
        final current = StringBuffer();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) {
            if (current.isNotEmpty) {
              merged.add(current.toString().trim());
              current.clear();
            }
            continue;
          }
          final isList = _isListLine(trimmed);
          final isHeading = _isHeadingLine(trimmed);

          if (isList || isHeading) {
            if (current.isNotEmpty) {
              merged.add(current.toString().trim());
              current.clear();
            }
            merged.add(trimmed);
            continue;
          }

          if (current.isNotEmpty) current.write(' ');
          current.write(trimmed);
        }
        if (current.isNotEmpty) merged.add(current.toString().trim());
        result.add(merged.join('\n\n'));
      }
    }

    return result.join('\n\n');
  }

  static String _splitIntoSentences(String text) {
    // Split on sentence endings while keeping the punctuation.
    final sentences = text.splitMapJoin(
      RegExp(r'(?<=[.!?])\s+(?=[A-Z0-9])'),
      onMatch: (_) => '\n\n',
      onNonMatch: (n) => n.trim(),
    );
    return sentences;
  }

  static String _preserveLists(String text) {
    final lines = text.split('\n');
    final buffer = StringBuffer();
    String? lastListPrefix;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        if (buffer.isNotEmpty) buffer.write('\n');
        lastListPrefix = null;
        continue;
      }

      final isNumbered = RegExp(r'^(\d+)[).-]\s*(.+)$').firstMatch(line);
      final isBullet = RegExp(r'^[-*•]\s*(.+)$').firstMatch(line);

      if (isNumbered != null) {
        final number = isNumbered.group(1)!;
        final content = isNumbered.group(2)!;
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write('$number. $content');
        lastListPrefix = '$number.';
      } else if (isBullet != null) {
        final content = isBullet.group(1)!;
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write('• $content');
        lastListPrefix = '•';
      } else {
        if (buffer.isNotEmpty && lastListPrefix != null) {
          // Append to previous list item if the line is a continuation.
          buffer.write(' $line');
          lastListPrefix = null; // only append once
        } else {
          if (buffer.isNotEmpty) buffer.write('\n');
          buffer.write(line);
          lastListPrefix = null;
        }
      }
    }

    return buffer.toString().replaceAll('\n\n\n', '\n\n');
  }

  static String _preserveHeadings(String text) {
    final lines = text.split('\n');
    final result = <String>[];

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        result.add('');
        continue;
      }

      // Short, all-caps, or numbered heading candidates stay on their own line.
      if (_isHeadingLine(line) || RegExp(r'^(\d+[).-]\s+)?[A-Z][A-Z\s]{2,}$').hasMatch(line)) {
        if (result.isNotEmpty && result.last.isNotEmpty) result.add('');
        result.add(line);
        result.add('');
      } else {
        result.add(line);
      }
    }

    return result.join('\n').replaceAll('\n\n\n', '\n\n');
  }

  static bool _isHeadingLine(String line) {
    return RegExp(r'^(Chapter|Section|Topic|Unit|Lesson|Module)\s+\d+', caseSensitive: false).hasMatch(line) ||
        RegExp(r'^(\d+\.[\d.]*\s+)').hasMatch(line);
  }

  static bool _isListLine(String line) {
    return RegExp(r'^(\d+[).-]\s+|[-*•]\s+)').hasMatch(line);
  }

  static String _cleanupWhitespace(String text) {
    return text
        .replaceAllMapped(RegExp(r'[ \t]+'), (_) => ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
