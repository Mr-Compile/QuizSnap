import 'package:flutter/material.dart';

class DeckDetailsTabletLayout extends StatelessWidget {
  final Widget left;
  final Widget right;

  const DeckDetailsTabletLayout({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 1200 ? 1200.0 : double.infinity;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Row(
            children: [
              // Left pane - Flashcard list (40% width)
              Expanded(
                flex: 40,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: left,
                ),
              ),
              // Right pane - Selection preview (60% width)
              Expanded(
                flex: 60,
                child: right,
              ),
            ],
          ),
        );
      },
    );
  }
}
