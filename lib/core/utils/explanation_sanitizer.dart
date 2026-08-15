/// Central formatter for AI-generated explanations.
///
/// Preserves readable structure (paragraphs, blank lines, numbered lists, and
/// bullet lists) while removing robotic filler and unsafe Markdown. This is the
/// single source of truth used by both the explanation bottom sheet and the
/// full explanation screen, guaranteeing identical rendering in both places.
///
/// The output is plain text with `\n` line breaks that [FormattedStudyText]
/// (backed by [StudyTextFormatter]) renders into themed paragraph/list widgets.
class ExplanationSanitizer {
  /// Words and phrases that sound robotic or AI-generated. Removed when leading.
  static final List<String> _fillerPrefixes = [
    'the correct answer is',
    'the answer is',
    'as an ai',
    'as a language model',
    'in conclusion',
    'to summarize',
    'to sum up',
    'ultimately',
    'overall',
    'therefore,',
    'thus,',
  ];

  /// Normalizes an explanation into readable, structured plain text.
  ///
  /// - Converts `\r\n` and `\r` to `\n`.
  /// - Preserves intentional paragraph breaks (blank lines).
  /// - Prevents excessive blank lines (collapses 3+ to 2).
  /// - Preserves numbered and bullet lists.
  /// - Normalizes accidental multiple spaces/tabs (without joining words).
  /// - Removes leading robotic filler phrases.
  /// - Strips unsafe Markdown that the renderer does not handle, while keeping
  ///   list markers (`1.`, `-`, `*`, `•`) intact for [StudyTextFormatter].
  ///
  /// [maxSentences] is accepted for backward compatibility but no longer
  /// truncates content — explanations are displayed in full so paragraphs and
  /// lists are never lost.
  static String sanitize(String? explanation, {int maxSentences = 0}) {
    if (explanation == null || explanation.trim().isEmpty) return '';

    // 1. Normalize line endings.
    String cleaned = explanation.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // 2. Strip fenced code blocks and inline code, links, and images.
    cleaned = cleaned
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAll(RegExp(r'`([^`]*)`'), r'$1')
        .replaceAll(RegExp(r'\[([^\]]*)\]\([^)]*\)'), r'$1')
        .replaceAll(RegExp(r'!?\[([^\]]*)\]'), r'$1');

    // 3. Remove bold/italic/underline markers but keep the wrapped text.
    cleaned = cleaned
        .replaceAll(RegExp(r'\*\*([^*]*)\*\*'), r'$1')
        .replaceAll(RegExp(r'__([^_]*)__'), r'$1')
        .replaceAll(RegExp(r'(?<!\w)\*([^*]*)\*(?!\w)'), r'$1')
        .replaceAll(RegExp(r'(?<!\w)_([^_]*)_(?!\w)'), r'$1');

    // 4. Strip leading Markdown heading markers (e.g. "## Why...").
    //    Keep the heading text so it reads as a section label.
    cleaned = cleaned.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*'), '');

    // 5. Normalize spaces/tabs within each line WITHOUT touching newlines,
    //    so words are never concatenated and lists stay on their own lines.
    final lines = cleaned.split('\n');
    final normalizedLines = <String>[];
    for (final line in lines) {
      // Collapse runs of spaces/tabs to a single space and trim edges.
      normalizedLines.add(line.replaceAll(RegExp(r'[ \t]+'), ' ').trim());
    }
    cleaned = normalizedLines.join('\n');

    // 6. Collapse 3+ consecutive newlines into a single blank line (two \n).
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

    // 7. Remove leading robotic filler phrases (only at the very start).
    final lower = cleaned.toLowerCase();
    for (final filler in _fillerPrefixes) {
      if (lower.startsWith(filler)) {
        cleaned = cleaned.substring(filler.length).trim();
        // Also remove a following colon or dash.
        cleaned = cleaned.replaceFirst(RegExp(r'^[\s:–—-]+'), '');
        break;
      }
    }

    // 8. Final tidy: collapse any blank lines that may have reappeared.
    return cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }
}
