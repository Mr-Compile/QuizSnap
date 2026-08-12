
/// Sanitizes AI-generated explanations into short, human-like, plain-text
/// study notes with no Markdown formatting.
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

  /// Sanitizes an explanation.
  ///
  /// - Strips all Markdown.
  /// - Removes leading filler phrases.
  /// - Truncates to at most [maxSentences] sentences.
  /// - Returns left-aligned, plain text.
  static String sanitize(String? explanation, {int maxSentences = 4}) {
    if (explanation == null || explanation.trim().isEmpty) return '';

    // 1. Strip Markdown and normalize whitespace.
    String cleaned = _stripMarkdown(explanation);

    // 2. Collapse spaces, keep paragraph breaks.
    cleaned = cleaned
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAllMapped(RegExp(r'[ \t]+'), (m) => ' ')
        .trim();

    // 3. Remove filler/robotic leading phrases.
    final lower = cleaned.toLowerCase();
    for (final filler in _fillerPrefixes) {
      if (lower.startsWith(filler)) {
        cleaned = cleaned.substring(filler.length).trim();
        // Also remove a following colon or dash.
        cleaned = cleaned.replaceFirst(RegExp(r'^[\s:–—-]+'), '');
        break;
      }
    }

    // 4. Split into sentences and keep the first [maxSentences] complete ones.
    final sentencePattern = RegExp(r'(?<=[.!?])\s+(?=[A-Z])');
    final rawSentences = cleaned.split(sentencePattern)
      ..removeWhere((s) => s.trim().isEmpty);

    if (rawSentences.isEmpty) return cleaned;

    final kept = rawSentences.take(maxSentences).toList();
    return kept.join(' ').trim();
  }

  /// Remove Markdown formatting, bullets, headings, and code markers.
  static String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'__'), '')
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll(RegExp(r'^\s*[-*•]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\d+[).-]?\s+', multiLine: true), '')
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAll(RegExp(r'`([^`]*)`'), r'$1')
        .replaceAll(RegExp(r'\[([^\]]*)\]\([^)]*\)'), r'$1')
        .replaceAll(RegExp(r'!?\[([^\]]*)\]'), r'$1')
        .replaceAll(RegExp(r'\*\s*'), ' ')
        .replaceAll(RegExp(r'_{2,}'), '');
  }
}
