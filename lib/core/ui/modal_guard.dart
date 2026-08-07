import 'package:flutter/material.dart';

/// ModalGuard utility to prevent duplicate modal dialogs and manage modal stacking
/// 
/// This utility helps manage modal interactions by:
/// - Preventing duplicate dialogs from opening
/// - Limiting modal stacking depth
/// - Providing keyboard dismissal on modal close
/// - Managing modal state across the application
class ModalGuard {
  ModalGuard._();

  static final ModalGuard _instance = ModalGuard._();
  factory ModalGuard() => _instance;

  // State management
  static bool _isDialogOpen = false;
  static bool _isBottomSheetOpen = false;
  static int _modalStackDepth = 0;
  static const int _maxModalDepth = 3;

  // Dialog queue management
  static final List<Function()> _dialogQueue = [];

  /// Check if a dialog can be shown
  static bool canShowDialog() {
    return !_isDialogOpen && _modalStackDepth < _maxModalDepth;
  }

  /// Check if a bottom sheet can be shown
  static bool canShowBottomSheet() {
    return !_isBottomSheetOpen && _modalStackDepth < _maxModalDepth;
  }

  /// Show a dialog with guard protection
  static Future<T?> showGuardedDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    String? barrierLabel,
    Color? barrierColor,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
  }) async {
    if (!canShowDialog()) {
      // Queue the dialog if another is open
      if (_dialogQueue.length < 5) {
        _dialogQueue.add(() {
          showGuardedDialog(
            context: context,
            builder: builder,
            barrierDismissible: barrierDismissible,
            barrierLabel: barrierLabel,
            barrierColor: barrierColor,
            useSafeArea: useSafeArea,
            useRootNavigator: useRootNavigator,
            routeSettings: routeSettings,
          );
        });
      }
      return null;
    }

    _isDialogOpen = true;
    _modalStackDepth++;

    try {
      final result = await showDialog<T>(
        context: context,
        builder: builder,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        barrierColor: barrierColor,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
      );

      _isDialogOpen = false;
      _modalStackDepth--;

      // Process next dialog in queue
      if (_dialogQueue.isNotEmpty) {
        final nextDialog = _dialogQueue.removeAt(0);
        Future.microtask(() => nextDialog());
      }

      return result;
    } catch (e) {
      _isDialogOpen = false;
      _modalStackDepth--;
      rethrow;
    }
  }

  /// Show a bottom sheet with guard protection
  static Future<T?> showGuardedBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool useSafeArea = true,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
    Offset? anchorPoint,
  }) async {
    if (!canShowBottomSheet()) {
      return null;
    }

    _isBottomSheetOpen = true;
    _modalStackDepth++;

    try {
      final result = await showModalBottomSheet<T>(
        context: context,
        builder: builder,
        isScrollControlled: isScrollControlled,
        useRootNavigator: useRootNavigator,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape,
        clipBehavior: clipBehavior,
        constraints: constraints,
        barrierColor: barrierColor,
        useSafeArea: useSafeArea,
        routeSettings: routeSettings,
        transitionAnimationController: transitionAnimationController,
        anchorPoint: anchorPoint,
      );

      _isBottomSheetOpen = false;
      _modalStackDepth--;

      // Dismiss keyboard when bottom sheet closes
      if (context.mounted) {
        FocusScope.of(context).unfocus();
      }

      return result;
    } catch (e) {
      _isBottomSheetOpen = false;
      _modalStackDepth--;
      rethrow;
    }
  }

  /// Dismiss all active modals
  static Future<void> dismissAllModals(BuildContext context) async {
    while (_modalStackDepth > 0) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      _modalStackDepth--;
    }
    _isDialogOpen = false;
    _isBottomSheetOpen = false;
    _dialogQueue.clear();
  }

  /// Get current modal stack depth
  static int get modalStackDepth => _modalStackDepth;

  /// Check if any modal is currently open
  static bool get isModalOpen => _isDialogOpen || _isBottomSheetOpen;

  /// Reset modal guard state (useful for testing)
  static void reset() {
    _isDialogOpen = false;
    _isBottomSheetOpen = false;
    _modalStackDepth = 0;
    _dialogQueue.clear();
  }
}

/// Extension to add guarded modal methods to BuildContext
extension ModalGuardNavigation on BuildContext {
  /// Show a guarded dialog
  Future<T?> showGuardedDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    String? barrierLabel,
    Color? barrierColor,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
  }) {
    return ModalGuard.showGuardedDialog(
      context: this,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );
  }

  /// Show a guarded bottom sheet
  Future<T?> showGuardedBottomSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool useSafeArea = true,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
    Offset? anchorPoint,
  }) {
    return ModalGuard.showGuardedBottomSheet(
      context: this,
      builder: builder,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
      routeSettings: routeSettings,
      transitionAnimationController: transitionAnimationController,
      anchorPoint: anchorPoint,
    );
  }
}