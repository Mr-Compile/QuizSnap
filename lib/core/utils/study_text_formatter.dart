import 'package:flutter/material.dart';

/// Parses study text into theme-adaptive, selectable, left-aligned widgets.
///
/// Preserves newlines, numbered lists (1., 2.), bullet lists (-, *, •),
/// and paragraph spacing while stripping leading Markdown markers.
class StudyTextFormatter {
  /// Splits a block of text into formatted paragraph/list widgets.
  static List<Widget> buildBlocks(
    BuildContext context,
    String text, {
    TextStyle? baseStyle,
    double paragraphSpacing = 12,
    double listIndent = 24,
  }) {
    final effectiveStyle = (baseStyle ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
        .copyWith(height: 1.5);
    final color = effectiveStyle.color ?? Theme.of(context).colorScheme.onSurface;
    final spans = <Widget>[];

    final raw = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = raw.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        // Preserve a visual paragraph break, but collapse consecutive blanks.
        if (spans.isNotEmpty && spans.last is! SizedBox) {
          spans.add(SizedBox(height: paragraphSpacing));
        }
        continue;
      }

      final numbered = _numberedPattern.firstMatch(line);
      final bullet = _bulletPattern.firstMatch(line);

      if (numbered != null) {
        final number = numbered.group(1);
        final content = line.substring(numbered.end).trim();
        spans.add(_buildListRow(
          context,
          leading: '$number. ',
          content: content,
          style: effectiveStyle,
          color: color,
          indent: listIndent,
        ));
      } else if (bullet != null) {
        final content = line.substring(bullet.end).trim();
        spans.add(_buildListRow(
          context,
          leading: '• ',
          content: content,
          style: effectiveStyle,
          color: color,
          indent: listIndent,
        ));
      } else {
        spans.add(
          Text.rich(
            TextSpan(
              text: _cleanMarkdown(line),
              style: effectiveStyle.copyWith(color: color),
            ),
            textAlign: TextAlign.start,
            softWrap: true,
          ),
        );
      }
    }

    return spans;
  }

  static final _numberedPattern = RegExp(r'^(\d+)[).-]?\s+');
  static final _bulletPattern = RegExp(r'^[\-*•]\s+');

  static String _cleanMarkdown(String line) {
    return line
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'__'), '')
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll(RegExp(r'^\s*[-*]\s*'), '')
        .replaceAll(RegExp(r'`'), '')
        .trim();
  }

  static Widget _buildListRow(
    BuildContext context, {
    required String leading,
    required String content,
    required TextStyle style,
    required Color color,
    double indent = 24,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            leading,
            style: style.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: _cleanMarkdown(content),
                style: style.copyWith(color: color),
              ),
              textAlign: TextAlign.start,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
