import 'package:flutter/material.dart';
import 'selection_preview_pane.dart';

/// Two-pane layout for tablet multi-selection in deck details.
///
/// [left] is the flashcard list. [right] is the selection preview pane.
class DeckDetailsTabletLayout extends StatelessWidget {
  final Widget left;
  final SelectionPreviewPane right;

  const DeckDetailsTabletLayout({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 45,
          child: left,
        ),
        Expanded(
          flex: 55,
          child: right,
        ),
      ],
    );
  }
}
