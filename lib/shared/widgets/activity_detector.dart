import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/session_inactivity_service.dart';

/// Wraps the app to detect real user interactions (taps, scrolls, swipes,
/// typing) and feeds them to [SessionInactivityService.recordActivity].
///
/// Uses a [Listener] for pointer events and a [Focus] widget for key events.
/// Does **not** count animations, rebuilds, timers, or network activity.
class ActivityDetector extends StatefulWidget {
  final Widget child;

  const ActivityDetector({super.key, required this.child});

  @override
  State<ActivityDetector> createState() => _ActivityDetectorState();
}

class _ActivityDetectorState extends State<ActivityDetector> {
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _record(context),
      onPointerMove: (_) => _record(context),
      onPointerUp: (_) => _record(context),
      child: Focus(
        onKeyEvent: (node, event) {
          _record(context);
          return KeyEventResult.ignored;
        },
        child: widget.child,
      ),
    );
  }

  void _record(BuildContext context) {
    try {
      context.read<SessionInactivityService>().recordActivity();
    } catch (_) {
      // Service may not be available during teardown.
    }
  }
}
