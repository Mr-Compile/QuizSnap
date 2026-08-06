import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utility class for handling back button behavior across the app
/// 
/// Provides consistent back button handling including:
/// - "Press back again to exit" protection
/// - Unsaved changes confirmation
/// - Modal dismissal before navigation
/// - Quiz/exam exit confirmation
class BackButtonHandler {
  BackButtonHandler._();

  /// Wrapper for PopScope with "press back again to exit" functionality
  static Widget withExitProtection({
    required Widget child,
    required BuildContext context,
    String message = 'Press back again to exit',
    Duration timeout = const Duration(seconds: 2),
  }) {
    return _ExitProtectionWrapper(
      child: child,
      message: message,
      timeout: timeout,
    );
  }

  /// Wrapper for PopScope with unsaved changes detection
  static Widget withUnsavedChangesProtection({
    required Widget child,
    required bool hasUnsavedChanges,
    required BuildContext context,
    String message = 'You have unsaved changes. Are you sure you want to leave?',
  }) {
    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && hasUnsavedChanges) {
          _showUnsavedChangesDialog(context, message);
        }
      },
      child: child,
    );
  }

  /// Wrapper for PopScope with custom confirmation dialog
  static Widget withConfirmation({
    required Widget child,
    required bool Function() shouldShowConfirmation,
    required Future<bool> Function() onConfirm,
    required BuildContext context,
    String title = 'Confirm',
    String message = 'Are you sure you want to go back?',
  }) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && shouldShowConfirmation()) {
          final confirmed = await _showConfirmationDialog(
            context,
            title: title,
            message: message,
          );
          if (confirmed) {
            if (await onConfirm()) {
              if (context.mounted) {
                context.pop();
              }
            }
          }
        }
      },
      child: child,
    );
  }

  static void _showUnsavedChangesDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.pop();
      }
    });
  }

  static Future<bool> _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _ExitProtectionWrapper extends StatefulWidget {
  final Widget child;
  final String message;
  final Duration timeout;

  const _ExitProtectionWrapper({
    required this.child,
    required this.message,
    required this.timeout,
  });

  @override
  State<_ExitProtectionWrapper> createState() => _ExitProtectionWrapperState();
}

class _ExitProtectionWrapperState extends State<_ExitProtectionWrapper> {
  DateTime? _lastBackPressTime;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    
    if (_lastBackPressTime == null || 
        now.difference(_lastBackPressTime!) > widget.timeout) {
      _lastBackPressTime = now;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.message),
            duration: widget.timeout,
          ),
        );
      }
      
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            context.pop();
          }
        }
      },
      child: widget.child,
    );
  }
}

/// Mixin for screens that need back button handling
mixin BackButtonHandlerMixin<T extends StatefulWidget> on State<T> {
  bool get hasUnsavedChanges => false;

  Future<bool> onBackPress() async => true;

  Widget buildWithBackButtonHandler(Widget child) {
    if (hasUnsavedChanges) {
      return BackButtonHandler.withUnsavedChangesProtection(
        child: child,
        hasUnsavedChanges: hasUnsavedChanges,
        context: context,
      );
    }
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await onBackPress();
          if (shouldPop && mounted) {
            context.pop();
          }
        }
      },
      child: child,
    );
  }
}