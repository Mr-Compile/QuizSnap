import '../models/document_section_model.dart';

/// Detects document sections from plain text using structural and typographic
/// heuristics (without modifying the text).
class HeadingDetectionService {
  static List<DocumentSection> detectSections(String text) {
    final lines = text.split('\n');
    final root = _SectionNode(title: 'Entire Document', level: 0, start: 0);
    final stack = <_SectionNode>[root];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final level = _headingLevel(line, i > 0 ? lines[i - 1].trim() : '');
      if (level == null) continue;

      final heading = line.replaceAll(_headingPrefixPattern, '').trim();

      // Close previous sections until we find the parent for this level.
      while (stack.length > 1 && stack.last.section.level >= level) {
        stack.last.section.endLine = i - 1;
        stack.removeLast();
      }

      final parent = stack.last;
      final node = _SectionNode(
        title: heading.isEmpty ? line : heading,
        level: level,
        start: i,
      );
      parent.children.add(node);
      stack.add(node);
    }

    // Close remaining sections.
    while (stack.isNotEmpty) {
      stack.last.section.endLine = lines.length - 1;
      stack.removeLast();
    }

    return root.children.map((n) => n.section).toList();
  }

  static final _headingPrefixPattern = RegExp(
    r"""^(\d+(\.\d+)*)\s*[).-]?\s+|^(Chapter|Section|Module|Unit|Lesson|Topic)\s+\d+[:.)-]?\s*""",
    caseSensitive: false,
  );

  static int? _headingLevel(String line, String previousLine) {
    // Numbered headings: 1., 1.1, 1.1.1 etc.
    final numbered = RegExp(r'^(\d+(?:\.\d+)*)\s*[).-]?\s+').firstMatch(line);
    if (numbered != null) {
      final level = numbered.group(1)!.split('.').length;
      return level.clamp(1, 4).toInt();
    }

    // Keyword headings such as "CHAPTER 1" or "SECTION A".
    final keyword = RegExp(
      r'^(Chapter|Section|Module|Unit|Lesson|Topic|Part|Appendix)\s+[A-Z0-9]+',
      caseSensitive: false,
    );
    if (keyword.hasMatch(line)) return 1;

    // Roman-numeral headings such as "I. Introduction" or "II. Background".
    final roman = RegExp(r'^(I{1,3}|IV|V|VI{0,3}|IX|X)\s*[).-]?\s+', caseSensitive: false);
    if (roman.hasMatch(line)) {
      return 1;
    }

    // All-caps short line is a heading only when it is isolated, short,
    // and does not end with sentence punctuation. This prevents classifying
    // normal uppercase paragraphs or lists as headings.
    if (line.length > 2 &&
        line.length <= 45 &&
        previousLine.isEmpty &&
        line == line.toUpperCase() &&
        !line.endsWith('.') &&
        !line.endsWith(',') &&
        !line.endsWith('!') &&
        !line.endsWith('?') &&
        !RegExp(r'[0-9]$').hasMatch(previousLine)) {
      return 1;
    }

    // Isolated short line ending without punctuation? Possibly a sub-heading.
    if (line.length > 45 ||
        line.length > 80 ||
        line.endsWith('.') ||
        line.endsWith(',') ||
        line.endsWith('!') ||
        line.endsWith('?')) {
      return null;
    }

    // Short line surrounded by blank lines (paragraph spacing).
    if (previousLine.isEmpty && line.length <= 45) {
      return 2;
    }

    return null;
  }
}

class _SectionNode {
  final DocumentSection section;
  final List<_SectionNode> children = [];

  _SectionNode({
    required String title,
    required int level,
    required int start,
  }) : section = DocumentSection(
          title: title,
          level: level,
          startLine: start,
          endLine: -1,
        );
}
