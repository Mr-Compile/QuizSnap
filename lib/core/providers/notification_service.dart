import 'dart:async';
import 'package:flutter/material.dart';

/// Lightweight model for a top banner.
class BannerMessage {
  final String id;
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final bool showUndo;
  final VoidCallback? onUndo;

  BannerMessage({
    required this.id,
    required this.message,
    this.icon = Icons.check_circle,
    this.backgroundColor = Colors.green,
    this.borderColor = Colors.green,
    this.iconColor = Colors.green,
    this.textColor = Colors.black,
    this.showUndo = false,
    this.onUndo,
  });
}

/// Lightweight model for a floating toast.
class ToastMessage {
  final String id;
  final String message;
  final IconData? icon;
  final Color? backgroundColor;
  final Color textColor;

  ToastMessage({
    required this.id,
    required this.message,
    this.icon,
    this.backgroundColor,
    this.textColor = Colors.white,
  });
}

/// Centralized notification service.
///
/// Shows top banners, floating toasts, and exposes an optional inline message
/// that can be consumed by screens that support inline status UI.
class NotificationService with ChangeNotifier {
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
      backgroundColor: const Color(0xFFF0FDF4),
      borderColor: const Color(0xFFBBF7D0),
      iconColor: const Color(0xFF16A34A),
      textColor: const Color(0xFF14532D),
      showUndo: showUndo,
      onUndo: onUndo,
    ));
  }

  void showInfoTop(String message) {
    showTopBanner(BannerMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      icon: Icons.info,
      backgroundColor: const Color(0xFFDBEAFE),
      borderColor: const Color(0xFF93C5FD),
      iconColor: const Color(0xFF2563EB),
      textColor: const Color(0xFF1E3A8A),
    ));
  }

  void showWarningTop(String message) {
    showTopBanner(BannerMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      icon: Icons.warning,
      backgroundColor: const Color(0xFFFEF9C3),
      borderColor: const Color(0xFFFDE047),
      iconColor: const Color(0xFFA16207),
      textColor: const Color(0xFF713F12),
    ));
  }

  void showErrorTop(String message) {
    showTopBanner(BannerMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      icon: Icons.error,
      backgroundColor: const Color(0xFFFEF2F2),
      borderColor: const Color(0xFFFECACA),
      iconColor: const Color(0xFFDC2626),
      textColor: const Color(0xFF7F1D1D),
    ));
  }

  void showToast(
    String message, {
    IconData? icon,
    Color? backgroundColor,
    Color textColor = Colors.white,
  }) {
    final toast = ToastMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      icon: icon,
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
      backgroundColor: const Color(0xFF16A34A),
    );
  }

  void showInfoToast(String message) {
    showToast(
      message,
      icon: Icons.info,
      backgroundColor: const Color(0xFF2563EB),
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

enum InlineMessageType { info, warning, error }
