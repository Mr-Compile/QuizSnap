import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/notification_service.dart';

/// Floating toast overlay that renders short-lived top-right or top-center
/// toasts without blocking bottom actions.
class AppToastOverlay extends StatelessWidget {
  final Widget child;

  const AppToastOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, service, _) {
        final toasts = service.toasts;

        if (toasts.isEmpty) {
          return child;
        }

        return Stack(
          children: [
            child,
            Positioned(
              top: 80,
              right: 16,
              left: 16,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: toasts.map((toast) => _ToastItem(toast: toast)).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ToastItem extends StatelessWidget {
  final ToastMessage toast;

  const _ToastItem({required this.toast});

  @override
  Widget build(BuildContext context) {
    final colors = _ToastColors.fromType(
      toast.type ?? InlineMessageType.info,
      Theme.of(context).colorScheme,
    );

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 250),
      child: Semantics(
        liveRegion: true,
        label: toast.message,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: toast.backgroundColor ?? colors.background,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (toast.icon != null) ...[
                Icon(
                  toast.icon,
                  color: toast.textColor ?? colors.foreground,
                  size: 16,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  toast.message,
                  style: TextStyle(
                    color: toast.textColor ?? colors.foreground,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToastColors {
  final Color background;
  final Color foreground;

  const _ToastColors({
    required this.background,
    required this.foreground,
  });

  factory _ToastColors.fromType(InlineMessageType type, ColorScheme colorScheme) {
    switch (type) {
      case InlineMessageType.success:
        return _ToastColors(
          background: colorScheme.primaryContainer,
          foreground: colorScheme.onPrimaryContainer,
        );
      case InlineMessageType.info:
        return _ToastColors(
          background: colorScheme.surfaceContainerHighest,
          foreground: colorScheme.onSurface,
        );
      case InlineMessageType.warning:
        return _ToastColors(
          background: colorScheme.tertiaryContainer,
          foreground: colorScheme.onTertiaryContainer,
        );
      case InlineMessageType.error:
        return _ToastColors(
          background: colorScheme.errorContainer,
          foreground: colorScheme.onErrorContainer,
        );
    }
  }
}
