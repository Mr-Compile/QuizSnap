import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      color: color,
      elevation: elevation ?? AppTheme.shadowSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingMd),
        child: child,
      ),
    );

    if (onTap != null || onLongPress != null) {
      return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: card,
      );
    }

    return card;
  }
}
