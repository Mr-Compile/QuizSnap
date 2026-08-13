import 'package:flutter/material.dart';
import '../../shared/widgets/dialogs/success_dialog.dart';
import '../../shared/widgets/dialogs/error_dialog.dart';
import '../../shared/widgets/dialogs/warning_dialog.dart';
import '../../shared/widgets/dialogs/info_dialog.dart';
import '../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../shared/widgets/dialogs/loading_dialog.dart';
import '../../shared/widgets/dialogs/no_internet_dialog.dart';

/// Safe, centered, Material 3 dialog feedback service.
///
/// Use instead of [ScaffoldMessenger] or inline [showDialog] calls that can
/// throw "No Overlay widget found" when called with an invalid or unmounted
/// [BuildContext].
///
/// Features:
/// * Every entry point checks `context.mounted` before and after the async gap.
/// * All dialogs are centered with smooth fade + scale animations.
/// * Theme-aware colors and spacing for dark/light mode.
/// * Educational-friendly copy and reassuring messages.
/// * Responsive layout for phones and tablets.
/// * Accessibility support with semantic labels and focus management.
/// * No global [BuildContext] is stored; callers pass a valid descendant context.
class DialogService {
  DialogService._();

  /// Show a success dialog with green icon and positive tone.
  static Future<void> showSuccess(
    BuildContext context,
    String message, {
    String title = 'Success',
    VoidCallback? onAcknowledge,
  }) async {
    if (!context.mounted) return;
    await SuccessDialog.show(
      context: context,
      title: title,
      message: message,
      actionLabel: 'OK',
      onAction: onAcknowledge,
    );
  }

  /// Show an error dialog with red icon and error tone.
  static Future<void> showError(
    BuildContext context,
    String message, {
    String title = 'Error',
    VoidCallback? onAcknowledge,
    String primaryAction = 'Try Again',
    String secondaryAction = 'Close',
    VoidCallback? onPrimaryAction,
    VoidCallback? onSecondaryAction,
  }) async {
    if (!context.mounted) return;
    await ErrorDialog.show(
      context: context,
      title: title,
      message: message,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      onPrimaryAction: onPrimaryAction ?? onAcknowledge,
      onSecondaryAction: onSecondaryAction,
    );
  }

  /// Show a warning dialog with amber icon and confirm/cancel actions.
  static Future<bool?> showWarning(
    BuildContext context,
    String message, {
    String title = 'Warning',
    String confirmAction = 'Confirm',
    String cancelAction = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    if (!context.mounted) return false;
    return await WarningDialog.show(
      context: context,
      title: title,
      message: message,
      confirmAction: confirmAction,
      cancelAction: cancelAction,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Show an info dialog with blue icon and single dismiss action.
  static Future<void> showInfo(
    BuildContext context,
    String message, {
    String title = 'Info',
    VoidCallback? onAcknowledge,
  }) async {
    if (!context.mounted) return;
    await InfoDialog.show(
      context: context,
      title: title,
      message: message,
      actionLabel: 'Got It',
      onAction: onAcknowledge,
    );
  }

  /// Show a confirmation dialog with neutral icon.
  static Future<bool?> showConfirmation(
    BuildContext context,
    String message, {
    String title = 'Confirm',
    String confirmAction = 'Confirm',
    String cancelAction = 'Cancel',
    bool isDestructive = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    if (!context.mounted) return false;
    return await ConfirmationDialog.show(
      context: context,
      title: title,
      message: message,
      confirmAction: confirmAction,
      cancelAction: cancelAction,
      isDestructive: isDestructive,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Friendly replacement for raw AI quota / token errors.
  static Future<void> showQuotaExceeded(BuildContext context) async {
    if (!context.mounted) return;
    await ErrorDialog.show(
      context: context,
      title: 'AI Limit Reached',
      message: 'You have reached today\'s AI generation limit. You can try again tomorrow or ask the administrator for additional quota.',
      primaryAction: 'OK',
      secondaryAction: '',
    );
  }

  /// Show the standardized No Internet dialog used by every AI feature.
  ///
  /// [onRetry] is invoked when the user taps Retry. [onClose] is invoked when
  /// the user dismisses the dialog. The dialog is non-dismissible via barrier
  /// tap so the user must explicitly choose an action.
  static Future<void> showNoInternet(
    BuildContext context, {
    VoidCallback? onRetry,
    VoidCallback? onClose,
  }) async {
    if (!context.mounted) return;
    await NoInternetDialog.show(
      context: context,
      onRetry: onRetry,
      onClose: onClose,
    );
  }

  /// Show the standardized "Explanation Unavailable" dialog used by the
  /// View Explanation flow when no explanation can be produced or fetched.
  static Future<void> showExplanationUnavailable(
    BuildContext context, {
    VoidCallback? onAcknowledge,
  }) async {
    if (!context.mounted) return;
    await InfoDialog.show(
      context: context,
      title: 'Explanation Unavailable',
      message: 'No explanation is available for this question yet.',
      actionLabel: 'OK',
      onAction: onAcknowledge,
    );
  }

  /// Show a loading dialog for long-running operations.
  static LoadingDialogController showLoading(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
  }) {
    if (!context.mounted) {
      return LoadingDialogController.noop();
    }
    return LoadingDialog.show(
      context: context,
      message: message,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Educational-friendly error messages for common scenarios.
  static String getFriendlyErrorMessage(String technicalMessage) {
    // Map technical errors to user-friendly messages
    final lowerMessage = technicalMessage.toLowerCase();

    if (lowerMessage.contains('exact alarm not permitted')) {
      return 'Study reminders are not available on this device right now.';
    }
    if (lowerMessage.contains('token limit') || lowerMessage.contains('quota')) {
      return 'You have reached today\'s AI generation limit.';
    }
    if (lowerMessage.contains('no overlay') || lowerMessage.contains('overlay widget')) {
      return 'Something went wrong while showing this message. Please try again.';
    }
    if (lowerMessage.contains('network') || lowerMessage.contains('connection')) {
      return 'Please check your internet connection and try again.';
    }
    if (lowerMessage.contains('permission')) {
      return 'The app needs permission to complete this action.';
    }
    if (lowerMessage.contains('storage') || lowerMessage.contains('disk')) {
      return 'Please check your available storage and try again.';
    }

    // Default: return a generic friendly message
    return 'Something went wrong. Please try again.';
  }

  /// Show error with friendly educational copy.
  static Future<void> showFriendlyError(
    BuildContext context,
    String technicalMessage, {
    String? title,
    VoidCallback? onAcknowledge,
  }) async {
    final friendlyMessage = getFriendlyErrorMessage(technicalMessage);
    await showError(
      context,
      friendlyMessage,
      title: title ?? 'Something Went Wrong',
      onAcknowledge: onAcknowledge,
    );
  }
}
