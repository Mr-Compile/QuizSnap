import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/notification_service.dart';

/// Deprecated name kept for compatibility.
///
/// Redirects to the new top banner notification system instead of a SnackBar.
class SuccessSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    context.read<NotificationService>().showSuccess(message);
  }
}
