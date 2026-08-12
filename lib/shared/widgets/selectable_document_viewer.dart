import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Displays a document's text with long-press / drag selection and reports
/// the selected substring back to the caller.
class SelectableDocumentViewer extends StatelessWidget {
  final String text;
  final ValueChanged<String>? onSelectionChanged;
  final TextStyle? style;

  const SelectableDocumentViewer({
    super.key,
    required this.text,
    this.onSelectionChanged,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: SelectableText(
        text,
        style: style ?? Theme.of(context).textTheme.bodyMedium,
        onSelectionChanged: (selection, _) {
          if (onSelectionChanged == null) return;
          final start = selection.start.clamp(0, text.length);
          final end = selection.end.clamp(0, text.length);
          if (start < end) {
            onSelectionChanged!(text.substring(start, end));
          } else {
            onSelectionChanged!('');
          }
        },
      ),
    );
  }
}
