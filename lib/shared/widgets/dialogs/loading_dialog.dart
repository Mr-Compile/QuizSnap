import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Loading dialog with centered circular progress indicator.
/// 
/// Non-dismissible by default. Used for operations like:
/// - AI generation
/// - Backup restore
/// - Import processing
/// - Delete operations
/// 
/// Example usage:
/// ```dart
/// final dialog = LoadingDialog.show(
///   context: context,
///   message: 'Generating questions...',
/// );
/// 
/// // Perform async operation
/// await someAsyncOperation();
/// 
/// // Dismiss when done
/// if (context.mounted) {
///   dialog.dismiss();
/// }
/// ```
class LoadingDialog extends StatelessWidget {
  final String? message;

  const LoadingDialog({
    super.key,
    this.message,
  });

  static LoadingDialogController show({
    required BuildContext context,
    String? message,
    bool barrierDismissible = false,
  }) {
    if (!context.mounted) {
      return LoadingDialogController.noop();
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Loading',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return LoadingDialog(message: message);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );

    return LoadingDialogController._(() {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return PopScope(
      canPop: false,
      child: Semantics(
        label: 'Loading${message != null ? ': $message' : ''}',
        child: AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
          ),
          elevation: 0,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? AppTheme.spacing8 : AppTheme.spacing6,
            vertical: AppTheme.spacing6,
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? AppTheme.spacing8 : AppTheme.spacing4,
            vertical: AppTheme.spacing8,
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 520 : double.infinity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(),
                ),
                if (message != null) ...[
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    message!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Controller for dismissing the loading dialog
class LoadingDialogController {
  final VoidCallback _dismiss;

  LoadingDialogController._(this._dismiss);

  /// Creates a no-op controller for cases where the dialog cannot be shown
  factory LoadingDialogController.noop() {
    return LoadingDialogController._(() {});
  }

  void dismiss() {
    _dismiss();
  }
}
