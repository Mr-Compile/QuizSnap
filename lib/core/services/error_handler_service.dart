import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dialog_service.dart';

enum ErrorType {
  network,
  permission,
  quotaExceeded,
  invalidApiKey,
  unsupportedModel,
  corruptedDocument,
  timeout,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message;
  final String? technicalDetails;
  final VoidCallback? onRetry;

  AppError({
    required this.type,
    required this.message,
    this.technicalDetails,
    this.onRetry,
  });

  factory AppError.network({String? message, VoidCallback? onRetry}) {
    return AppError(
      type: ErrorType.network,
      message: message ?? 'Network connection failed. Please check your internet connection.',
      onRetry: onRetry,
    );
  }

  factory AppError.permission({String? message, VoidCallback? onRetry}) {
    return AppError(
      type: ErrorType.permission,
      message: message ?? 'Permission denied. Please grant the required permissions.',
      onRetry: onRetry,
    );
  }

  factory AppError.quotaExceeded({String? message, VoidCallback? onRetry}) {
    return AppError(
      type: ErrorType.quotaExceeded,
      message: message ?? 'Daily AI quota exceeded. Please try again tomorrow.',
      onRetry: onRetry,
    );
  }

  factory AppError.invalidApiKey({String? message, VoidCallback? onRetry}) {
    return AppError(
      type: ErrorType.invalidApiKey,
      message: message ?? 'Invalid API key. Please check your API configuration.',
      onRetry: onRetry,
    );
  }

  factory AppError.unsupportedModel({String? message, VoidCallback? onRetry}) {
    return AppError(
      type: ErrorType.unsupportedModel,
      message: message ?? 'Selected AI model is not available. Falling back to default model.',
      onRetry: onRetry,
    );
  }

  factory AppError.corruptedDocument({String? message, VoidCallback? onRetry}) {
    return AppError(
      type: ErrorType.corruptedDocument,
      message: message ?? 'Document file is corrupted or unsupported.',
      onRetry: onRetry,
    );
  }

  factory AppError.timeout({String? message, VoidCallback? onRetry}) {
    return AppError(
      type: ErrorType.timeout,
      message: message ?? 'Request timed out. Please try again.',
      onRetry: onRetry,
    );
  }

  factory AppError.unknown({String? message, VoidCallback? onRetry}) {
    return AppError(
      type: ErrorType.unknown,
      message: message ?? 'An unexpected error occurred. Please try again.',
      onRetry: onRetry,
    );
  }

  IconData get icon {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.permission:
        return Icons.lock;
      case ErrorType.quotaExceeded:
        return Icons.block;
      case ErrorType.invalidApiKey:
        return Icons.key_off;
      case ErrorType.unsupportedModel:
        return Icons.psychology_alt;
      case ErrorType.corruptedDocument:
        return Icons.file_present;
      case ErrorType.timeout:
        return Icons.schedule;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  Color get color {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.permission:
        return Colors.red;
      case ErrorType.quotaExceeded:
        return Colors.purple;
      case ErrorType.invalidApiKey:
        return Colors.red;
      case ErrorType.unsupportedModel:
        return Colors.orange;
      case ErrorType.corruptedDocument:
        return Colors.red;
      case ErrorType.timeout:
        return Colors.orange;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }
}

class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      // If connectivity check fails, assume online to avoid blocking functionality
      return true;
    }
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    AppError error, {
    String? title,
  }) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(error.icon, color: error.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title ?? 'Error'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.message),
            if (error.technicalDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                error.technicalDetails!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (error.onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                error.onRetry!();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  static void showErrorSnackBar(
    BuildContext context,
    AppError error, {
    SnackBarAction? action,
  }) {
    DialogService.showError(context, error.message);
  }

  /// Show success dialog
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    VoidCallback? action,
    String? actionLabel,
  }) {
    DialogService.showSuccess(context, message);
  }

  /// Show loading snackbar
  static ScaffoldFeatureController showLoadingSnackBar(
    BuildContext context,
    String message,
  ) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        duration: const Duration(days: 1), // Indeterminate loading
      ),
    );
  }

  /// Handle exception and convert to AppError
  static AppError handleException(dynamic exception, {VoidCallback? onRetry}) {
    if (exception is AppError) {
      return exception;
    }

    final message = exception.toString();
    
    if (message.contains('network') || message.contains('connection') || message.contains('internet')) {
      return AppError.network(message: message, onRetry: onRetry);
    } else if (message.contains('permission') || message.contains('access denied')) {
      return AppError.permission(message: message, onRetry: onRetry);
    } else if (message.contains('quota') || message.contains('limit')) {
      return AppError.quotaExceeded(message: message, onRetry: onRetry);
    } else if (message.contains('API key') || message.contains('authentication')) {
      return AppError.invalidApiKey(message: message, onRetry: onRetry);
    } else if (message.contains('model') || message.contains('groq')) {
      return AppError.unsupportedModel(message: message, onRetry: onRetry);
    } else if (message.contains('document') || message.contains('file') || message.contains('corrupted')) {
      return AppError.corruptedDocument(message: message, onRetry: onRetry);
    } else if (message.contains('timeout') || message.contains('timed out')) {
      return AppError.timeout(message: message, onRetry: onRetry);
    } else {
      return AppError.unknown(message: message, onRetry: onRetry);
    }
  }
}