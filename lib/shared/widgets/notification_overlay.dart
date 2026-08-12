import 'package:flutter/material.dart';
import 'app_toast_overlay.dart';
import 'top_banner_overlay.dart';

/// Wraps the whole app with both the top banner and floating toast overlays
/// so notifications can be shown from any provider or screen without a
/// [ScaffoldMessenger].
class NotificationOverlay extends StatelessWidget {
  final Widget child;

  const NotificationOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TopBannerOverlay(
      child: AppToastOverlay(
        child: child,
      ),
    );
  }
}
