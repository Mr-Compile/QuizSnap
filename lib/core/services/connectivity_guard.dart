import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dialog_service.dart';

/// Centralized guard for AI features that require internet access.
///
/// Before any AI request (Generate Quiz, Generate Flashcards, AI Explanation,
/// AI Regenerate, Analyze Document), callers should use [run] to ensure the
/// device is online. When offline, a friendly No Internet dialog is shown and
/// the action is blocked.
///
/// Usage:
/// ```dart
/// final ok = await ConnectivityGuard.run(context, () async {
///   await _generateQuestions();
/// });
/// ```
class ConnectivityGuard {
  ConnectivityGuard._();

  /// Returns true if the device currently has any connectivity
  /// (Wi-Fi, mobile, ethernet, etc.). Returns false only when the result is
  /// [ConnectivityResult.none]. If the connectivity check itself fails, we
  /// optimistically return true so users on flaky platforms are not blocked.
  static Future<bool> isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (_) {
      return true;
    }
  }

  /// Runs [action] only when the device is online. When offline, shows the
  /// standardized No Internet dialog with a Retry button that re-runs the
  /// guard. Returns true if [action] completed, false if it was blocked.
  static Future<bool> run(
    BuildContext context,
    Future<void> Function() action, {
    VoidCallback? onClose,
  }) async {
    if (!context.mounted) return false;

    final online = await isOnline();
    if (!context.mounted) return false;

    if (online) {
      try {
        await action();
        return true;
      } catch (e) {
        // If the action itself fails with a network-shaped error, surface the
        // friendly No Internet dialog instead of the raw technical message.
        final message = e.toString().toLowerCase();
        if (message.contains('socket') ||
            message.contains('network') ||
            message.contains('connection') ||
            message.contains('host') ||
            message.contains('failed host lookup')) {
          if (!context.mounted) return false;
          await DialogService.showNoInternet(
            context,
            onRetry: () => run(context, action, onClose: onClose),
            onClose: onClose,
          );
          return false;
        }
        // Otherwise rethrow so the caller can handle the non-network error.
        rethrow;
      }
    }

    await DialogService.showNoInternet(
      context,
      onRetry: () => run(context, action, onClose: onClose),
      onClose: onClose,
    );
    return false;
  }
}
