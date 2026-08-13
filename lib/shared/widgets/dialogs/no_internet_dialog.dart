import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'app_dialog.dart';

/// Standardized No Internet dialog used by every AI feature before issuing a
/// network request. Shows a friendly message with Retry and Close actions.
///
/// Example usage:
/// ```dart
/// await DialogService.showNoInternet(
///   context,
///   onRetry: () => _retryAction(),
/// );
/// ```
class NoInternetDialog extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onClose;
  final bool barrierDismissible;

  const NoInternetDialog({
    super.key,
    this.onRetry,
    this.onClose,
    this.barrierDismissible = false,
  });

  static Future<void> show({
    required BuildContext context,
    VoidCallback? onRetry,
    VoidCallback? onClose,
    bool barrierDismissible = false,
  }) async {
    if (!context.mounted) return;

    await AppDialog.show(
      context: context,
      title: 'No Internet Connection',
      message:
          'AI features require an internet connection. Please connect to Wi-Fi or mobile data and try again.',
      icon: Icons.wifi_off_rounded,
      iconColor: AppTheme.amber500,
      barrierDismissible: barrierDismissible,
      actions: [
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onClose?.call();
          },
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRetry?.call();
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provided for backward compatibility - prefer the static show() method.
    return const SizedBox.shrink();
  }
}
