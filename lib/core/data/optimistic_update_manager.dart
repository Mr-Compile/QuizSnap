import 'package:flutter/material.dart';

/// OptimisticUpdateManager handles optimistic UI updates for CRUD operations
/// 
/// This utility provides:
/// - Immediate UI feedback before server/database confirmation
/// - Automatic rollback on failure
/// - Loading state management
/// - Error recovery
class OptimisticUpdateManager<T> {
  OptimisticUpdateManager({
    required this.onUpdate,
    required this.onRollback,
    this.showErrorSnackBar = true,
  });

  final Future<void> Function(T data) onUpdate;
  final Future<void> Function(T data) onRollback;
  final bool showErrorSnackBar;

  bool _isUpdating = false;
  T? _originalData;
  T? _optimisticData;

  /// Perform an optimistic update
  Future<bool> execute({
    required BuildContext context,
    required T originalData,
    required T optimisticData,
    String? successMessage,
    String? errorMessage,
  }) async {
    if (_isUpdating) {
      _showError(context, 'Operation in progress');
      return false;
    }

    _isUpdating = true;
    _originalData = originalData;
    _optimisticData = optimisticData;

    try {
      // Apply optimistic update immediately
      await onUpdate(optimisticData);

      // Perform actual update
      // Note: The actual async operation should be called by the caller
      // This manager handles the UI state management
      
      return true;
    } catch (e) {
      // Rollback on error
      final original = _originalData;
      if (original != null) {
        await onRollback(original);
      }
      
      if (context.mounted) {
        _showError(context, errorMessage ?? 'Update failed: $e');
      }
      return false;
    } finally {
      _isUpdating = false;
    }
  }

  /// Rollback the optimistic update
  Future<void> rollback() async {
    final original = _originalData;
    if (original != null) {
      await onRollback(original);
    }
    _isUpdating = false;
  }

  /// Check if an update is in progress
  bool get isUpdating => _isUpdating;

  /// Get the original data before optimistic update
  T? get originalData => _originalData;

  /// Get the optimistic data
  T? get optimisticData => _optimisticData;

  void _showError(BuildContext context, String message) {
    if (showErrorSnackBar && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

/// Optimistic CRUD operations helper
class OptimisticCRUD {
  OptimisticCRUD._();

  /// Optimistic delete operation
  static Future<bool> deleteItem<T>({
    required BuildContext context,
    required T item,
    required Future<void> Function(T item) onDelete,
    required Future<void> Function(T item) onRollback,
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      // Remove from UI immediately
      await onDelete(item);

      // Perform actual delete (caller should handle this)
      // If successful, show success message
      if (successMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }

      return true;
    } catch (e) {
      // Rollback: add item back to UI
      await onRollback(item);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Delete failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }

      return false;
    }
  }

  /// Optimistic create operation
  static Future<bool> createItem<T>({
    required BuildContext context,
    required T item,
    required Future<void> Function(T item) onCreate,
    required Future<void> Function(T item) onRollback,
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      // Add to UI immediately
      await onCreate(item);

      // Perform actual create (caller should handle this)
      if (successMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }

      return true;
    } catch (e) {
      // Rollback: remove from UI
      await onRollback(item);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Create failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }

      return false;
    }
  }

  /// Optimistic update operation
  static Future<bool> updateItem<T>({
    required BuildContext context,
    required T originalItem,
    required T updatedItem,
    required Future<void> Function(T originalItem, T updatedItem) onUpdate,
    required Future<void> Function(T originalItem) onRollback,
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      // Update in UI immediately
      await onUpdate(originalItem, updatedItem);

      // Perform actual update (caller should handle this)
      if (successMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }

      return true;
    } catch (e) {
      // Rollback: revert to original
      await onRollback(originalItem);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Update failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }

      return false;
    }
  }
}

/// Extension to add optimistic CRUD methods to BuildContext
extension OptimisticCRUDNavigation on BuildContext {
  /// Perform optimistic delete
  Future<bool> optimisticDelete<T>({
    required T item,
    required Future<void> Function(T item) onDelete,
    required Future<void> Function(T item) onRollback,
    String? successMessage,
    String? errorMessage,
  }) {
    return OptimisticCRUD.deleteItem(
      context: this,
      item: item,
      onDelete: onDelete,
      onRollback: onRollback,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  /// Perform optimistic create
  Future<bool> optimisticCreate<T>({
    required T item,
    required Future<void> Function(T item) onCreate,
    required Future<void> Function(T item) onRollback,
    String? successMessage,
    String? errorMessage,
  }) {
    return OptimisticCRUD.createItem(
      context: this,
      item: item,
      onCreate: onCreate,
      onRollback: onRollback,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  /// Perform optimistic update
  Future<bool> optimisticUpdate<T>({
    required T originalItem,
    required T updatedItem,
    required Future<void> Function(T originalItem, T updatedItem) onUpdate,
    required Future<void> Function(T originalItem) onRollback,
    String? successMessage,
    String? errorMessage,
  }) {
    return OptimisticCRUD.updateItem(
      context: this,
      originalItem: originalItem,
      updatedItem: updatedItem,
      onUpdate: onUpdate,
      onRollback: onRollback,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}