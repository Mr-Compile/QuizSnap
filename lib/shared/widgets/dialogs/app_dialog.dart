import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Base dialog widget that provides centered, Material 3-compliant dialog layout.
/// 
/// Features:
/// - Vertically and horizontally centered
/// - Respects safe areas
/// - Responsive max width (90% on phone, 420-520dp on tablet)
/// - Smooth fade + scale animation (180-240ms)
/// - Theme-aware colors and spacing
/// - Accessibility support (semantic labels, focus management)
class AppDialog extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final Color? iconColor;
  final Widget? customIcon;
  final List<Widget> actions;
  final bool barrierDismissible;
  final VoidCallback? onDismiss;

  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.iconColor,
    this.customIcon,
    this.actions = const [],
    this.barrierDismissible = true,
    this.onDismiss,
  });

  /// Shows the dialog with centered animation
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    IconData? icon,
    Color? iconColor,
    Widget? customIcon,
    List<Widget> actions = const [],
    bool barrierDismissible = true,
    VoidCallback? onDismiss,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss dialog',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AppDialog(
          title: title,
          message: message,
          icon: icon,
          iconColor: iconColor,
          customIcon: customIcon,
          actions: actions,
          barrierDismissible: barrierDismissible,
          onDismiss: onDismiss,
        );
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return PopScope(
      canPop: barrierDismissible,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          onDismiss?.call();
        }
      },
      child: Semantics(
        label: 'Dialog: $title',
        namesRoute: true,
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
                if (customIcon != null || icon != null) ...[
                  _buildIcon(colorScheme),
                  const SizedBox(height: AppTheme.spacing4),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: isTablet ? AppTheme.text2xl : AppTheme.textLg,
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  const SizedBox(height: AppTheme.spacing3),
                  Text(
                    message!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacing5),
                  _buildActions(context, isTablet, colorScheme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ColorScheme colorScheme) {
    if (customIcon != null) {
      return SizedBox(
        width: 64,
        height: 64,
        child: customIcon,
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: iconColor ?? colorScheme.primary,
        size: 32,
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isTablet, ColorScheme colorScheme) {
    if (isTablet) {
      // Horizontal layout for tablets
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions
            .map((action) => Padding(
                  padding: const EdgeInsets.only(left: AppTheme.spacing2),
                  child: action,
                ))
            .toList(),
      );
    } else {
      // Vertical stacked layout for phones
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: actions
            .map((action) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing2),
                  child: SizedBox(
                    width: double.infinity,
                    child: action,
                  ),
                ))
            .toList(),
      );
    }
  }
}
