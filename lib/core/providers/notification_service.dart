import 'dart:async';
import 'package:flutter/material.dart';

/// Lightweight model for a top banner.
class BannerMessage {
  final String id;
  final String message;
  final IconData icon;
  final InlineMessageType type;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final Color? textColor;
  final bool showUndo;
  final VoidCallback? onUndo;

  BannerMessage({
    required this.id,
    required this.message,
    this.icon = Icons.check_circle,
    required this.type,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.textColor,
    this.showUndo = false,
    this.onUndo,
  });
}

/// Lightweight model for a floating toast.
class ToastMessage {
  final String id;
  final String message;
  final IconData? icon;
  final InlineMessageType? type;
  final Color? backgroundColor;
  final Color? textColor;

  ToastMessage({
    required this.id,
    required this.message,
    this.icon,
    this.type,
    this.backgroundColor,
    this.textColor,
  });
}

/// Centralized notification service.
///
/// Shows top banners, floating toasts, and exposes an optional inline message
/// that can be consumed by screens that support inline status UI.
class NotificationService with ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<BannerMessage> _banners = [];
  final List<ToastMessage> _toasts = [];
  String? _inlineMessage;
  InlineMessageType _inlineType = InlineMessageType.info;

  List<BannerMessage> get banners => List.unmodifiable(_banners);
  List<ToastMessage> get toasts => List.unmodifiable(_toasts);
  String? get inlineMessage => _inlineMessage;
  InlineMessageType get inlineType => _inlineType;

  void showTopBanner(BannerMessage banner) {
    _banners.add(banner);
    notifyListeners();
    _scheduleBannerDismiss(banner.id);
  }

  void showSuccess(
    String message, {
    bool showUndo = false,
    VoidCallback? onUndo,
    IconData icon = Icons.check_circle,
  }) {
    showTopBanner(BannerMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      icon: icon,
      type: InlineMessageType.success,
      showUndo: showUndo,
      onUndo: onUndo,
    ));
  }

  void showInfoTop(String message) {
    showTopBanner(BannerMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      icon: Icons.info,
      type: InlineMessageType.info,
    ));
  }

  void showWarningTop(String message) {
    showTopBanner(BannerMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      icon: Icons.warning,
      type: InlineMessageType.warning,
    ));
  }

  void showErrorTop(String message) {
    showTopBanner(BannerMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      icon: Icons.error,
      type: InlineMessageType.error,
    ));
  }

  void showToast(
    String message, {
    IconData? icon,
    InlineMessageType? type,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final toast = ToastMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      icon: icon,
      type: type,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
    _toasts.add(toast);
    notifyListeners();
    _scheduleToastDismiss(toast.id);
  }

  void showSuccessToast(String message, {IconData icon = Icons.check}) {
    showToast(
      message,
      icon: icon,
      type: InlineMessageType.success,
    );
  }

  void showInfoToast(String message) {
    showToast(
      message,
      icon: Icons.info,
      type: InlineMessageType.info,
    );
  }

  void showInline(String message, InlineMessageType type) {
    _inlineMessage = message;
    _inlineType = type;
    notifyListeners();
  }

  void clearInline() {
    _inlineMessage = null;
    notifyListeners();
  }

  void dismissBanner(String id) {
    _banners.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  void dismissToast(String id) {
    _toasts.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void _scheduleBannerDismiss(String id) {
    Timer(const Duration(seconds: 3), () => dismissBanner(id));
  }

  void _scheduleToastDismiss(String id) {
    Timer(const Duration(milliseconds: 1500), () => dismissToast(id));
  }
}

enum InlineMessageType { info, warning, error, success }
