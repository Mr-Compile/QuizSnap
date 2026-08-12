/// Represents a hierarchical section in a document.
class DocumentSection {
  final String title;
  final int level;
  final int startLine;
  int endLine;
  final List<DocumentSection> children;
  bool isSelected;
  bool isExpanded;

  DocumentSection({
    required this.title,
    required this.level,
    required this.startLine,
    this.endLine = -1,
    this.children = const [],
    this.isSelected = false,
    this.isExpanded = true,
  });

  /// Returns a flat list of this section and all descendants.
  List<DocumentSection> toFlatList() {
    final result = <DocumentSection>[this];
    for (final child in children) {
      result.addAll(child.toFlatList());
    }
    return result;
  }

  /// Combine all selected sections (and their children) into a single text.
  static String selectedText(List<DocumentSection> sections, List<String> lines) {
    final selected = _collectSelected(sections);
    if (selected.isEmpty) return '';

    final buffer = StringBuffer();
    for (final section in selected) {
      if (buffer.isNotEmpty) buffer.write('\n\n');
      for (int i = section.startLine; i <= section.endLine && i < lines.length; i++) {
        if (i > section.startLine) buffer.write('\n');
        buffer.write(lines[i]);
      }
    }
    return buffer.toString();
  }

  static List<DocumentSection> _collectSelected(List<DocumentSection> sections) {
    final result = <DocumentSection>[];
    for (final section in sections) {
      if (section.isSelected) {
        result.add(section);
      } else {
        result.addAll(_collectSelected(section.children));
      }
    }
    return result;
  }

  /// Estimated question count based on line / content density.
  int estimatedQuestionCount() {
    final length = endLine - startLine + 1;
    if (length <= 0) return 0;
    // Rough heuristic: one question per ~8 content lines.
    return (length / 8).clamp(1, 50).ceil();
  }
}
