import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/notification_service.dart';

/// Global overlay that listens to [NotificationService] and renders temporary
/// top banners below the app bar. Banners auto-dismiss and are swipeable.
class TopBannerOverlay extends StatelessWidget {
  final Widget child;

  const TopBannerOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, service, _) {
        final banners = service.banners;

        if (banners.isEmpty) {
          return child;
        }

        return SafeArea(
          child: Stack(
            children: [
              child,
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: banners.map((banner) => _BannerItem(banner: banner)).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BannerItem extends StatelessWidget {
  final BannerMessage banner;

  const _BannerItem({required this.banner});

  @override
  Widget build(BuildContext context) {
    final service = context.read<NotificationService>();
    final colors = _BannerColors.fromType(banner.type, Theme.of(context).colorScheme);

    return Dismissible(
      key: Key(banner.id),
      direction: DismissDirection.up,
      onDismissed: (_) => service.dismissBanner(banner.id),
      child: Semantics(
        liveRegion: true,
        label: banner.message,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: banner.backgroundColor ?? colors.background,
            border: Border.all(
              color: banner.borderColor ?? colors.border,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                banner.icon,
                color: banner.iconColor ?? colors.icon,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  banner.message,
                  style: TextStyle(
                    color: banner.textColor ?? colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (banner.showUndo) ...[
                TextButton(
                  onPressed: () {
                    service.dismissBanner(banner.id);
                    banner.onUndo?.call();
                  },
                  child: Text(
                    'UNDO',
                    style: TextStyle(
                      color: banner.iconColor ?? colors.icon,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: banner.iconColor ?? colors.icon,
                  size: 18,
                ),
                onPressed: () => service.dismissBanner(banner.id),
                tooltip: 'Dismiss',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerColors {
  final Color background;
  final Color border;
  final Color icon;
  final Color text;

  const _BannerColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.text,
  });

  factory _BannerColors.fromType(InlineMessageType type, ColorScheme colorScheme) {
    switch (type) {
      case InlineMessageType.success:
        return _BannerColors(
          background: colorScheme.primaryContainer,
          border: colorScheme.primary,
          icon: colorScheme.primary,
          text: colorScheme.onPrimaryContainer,
        );
      case InlineMessageType.info:
        return _BannerColors(
          background: colorScheme.surfaceContainerHighest,
          border: colorScheme.outline,
          icon: colorScheme.primary,
          text: colorScheme.onSurface,
        );
      case InlineMessageType.warning:
        return _BannerColors(
          background: colorScheme.tertiaryContainer,
          border: colorScheme.tertiary,
          icon: colorScheme.tertiary,
          text: colorScheme.onTertiaryContainer,
        );
      case InlineMessageType.error:
        return _BannerColors(
          background: colorScheme.errorContainer,
          border: colorScheme.error,
          icon: colorScheme.error,
          text: colorScheme.onErrorContainer,
        );
    }
  }
}
