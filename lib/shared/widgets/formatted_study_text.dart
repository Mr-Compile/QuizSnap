import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/dialog_service.dart';
import '../../core/utils/study_text_formatter.dart';

/// A reusable, theme-adaptive widget that renders study text with preserved
/// newlines, numbered lists, bullets, and left-aligned wrapping.
///
/// The text is wrapped in a [SelectionArea] so users can copy/select content.
/// Optional copy/share action buttons are available via [showActions].
class FormattedStudyText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final EdgeInsets padding;
  final double paragraphSpacing;
  final double listIndent;
  final double? maxContentWidth;
  final bool showActions;

  const FormattedStudyText({
    super.key,
    required this.text,
    this.style,
    this.padding = EdgeInsets.zero,
    this.paragraphSpacing = 12,
    this.listIndent = 24,
    this.maxContentWidth = 720,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = StudyTextFormatter.buildBlocks(
      context,
      text,
      baseStyle: style,
      paragraphSpacing: paragraphSpacing,
      listIndent: listIndent,
    );

    Widget content = SelectionArea(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: blocks,
        ),
      ),
    );

    if (maxContentWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth!),
        child: content,
      );
    }

    if (showActions) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionBar(context),
          content,
        ],
      );
    }

    return content;
  }

  Widget _buildActionBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                DialogService.showSuccess(context, 'Copied to clipboard');
              }
            },
            tooltip: 'Copy text',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(text),
            tooltip: 'Share text',
          ),
        ],
      ),
    );
  }
}
