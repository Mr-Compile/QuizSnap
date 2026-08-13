import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// UnsavedChangesIndicator shows a visual indicator when a form has unsaved changes
/// 
/// This widget provides:
/// - Visual indicator (asterisk, dot, or custom)
/// - Automatic showing/hiding based on unsaved state
/// - Consistent styling with AppTheme
/// - Customizable appearance
class UnsavedChangesIndicator extends StatelessWidget {
  final bool hasUnsavedChanges;
  final IndicatorStyle style;
  final Color? color;
  final double? size;

  const UnsavedChangesIndicator({
    super.key,
    required this.hasUnsavedChanges,
    this.style = IndicatorStyle.asterisk,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasUnsavedChanges) {
      return const SizedBox.shrink();
    }

    final indicatorColor = color ?? Theme.of(context).colorScheme.error;
    final indicatorSize = size ?? 16.0;

    switch (style) {
      case IndicatorStyle.asterisk:
        return Text(
          '*',
          style: TextStyle(
            color: indicatorColor,
            fontSize: indicatorSize,
            fontWeight: FontWeight.bold,
          ),
        );
      case IndicatorStyle.dot:
        return Container(
          width: indicatorSize,
          height: indicatorSize,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
          ),
        );
      case IndicatorStyle.circle:
        return Container(
          width: indicatorSize,
          height: indicatorSize,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: indicatorColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        );
      case IndicatorStyle.badge:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacingXs,
          ),
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Text(
            'Unsaved',
            style: AppTheme.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: indicatorSize * 0.75,
            ),
          ),
        );
    }
  }
}

enum IndicatorStyle {
  asterisk,
  dot,
  circle,
  badge,
}

/// UnsavedChangesAppBar adds unsaved changes indicator to AppBar
class UnsavedChangesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool hasUnsavedChanges;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final IndicatorStyle indicatorStyle;

  const UnsavedChangesAppBar({
    super.key,
    required this.title,
    required this.hasUnsavedChanges,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.indicatorStyle = IndicatorStyle.asterisk,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Text(title),
          if (hasUnsavedChanges) ...[
            const SizedBox(width: AppTheme.spacingXs),
            UnsavedChangesIndicator(
              hasUnsavedChanges: hasUnsavedChanges,
              style: indicatorStyle,
            ),
          ],
        ],
      ),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// UnsavedChangesFloatingActionButton shows unsaved changes indicator on FAB
class UnsavedChangesFloatingActionButton extends StatelessWidget {
  final bool hasUnsavedChanges;
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final IndicatorStyle indicatorStyle;

  const UnsavedChangesFloatingActionButton({
    super.key,
    required this.hasUnsavedChanges,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.indicatorStyle = IndicatorStyle.dot,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          tooltip: tooltip,
          child: Icon(icon),
        ),
        if (hasUnsavedChanges)
          Positioned(
            right: 0,
            top: 0,
            child: UnsavedChangesIndicator(
              hasUnsavedChanges: true,
              style: indicatorStyle,
              size: 12,
            ),
          ),
      ],
    );
  }
}

/// UnsavedChangesTabBar shows unsaved changes indicator on TabBar
class UnsavedChangesTabBar extends StatelessWidget {
  final List<Tab> tabs;
  final bool hasUnsavedChanges;
  final TabController? controller;
  final bool isScrollable;
  final IndicatorStyle indicatorStyle;
  final int? unsavedTabIndex;

  const UnsavedChangesTabBar({
    super.key,
    required this.tabs,
    required this.hasUnsavedChanges,
    this.controller,
    this.isScrollable = false,
    this.indicatorStyle = IndicatorStyle.dot,
    this.unsavedTabIndex,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      tabs: tabs.asMap().entries.map((entry) {
        final index = entry.key;
        final tab = entry.value;
        final showIndicator = hasUnsavedChanges && 
            (unsavedTabIndex == null || unsavedTabIndex == index);
        
        return Tab(
          child: Row(
            children: [
              if (tab.child != null) tab.child!,
              if (showIndicator) ...[
                const SizedBox(width: AppTheme.spacingXs),
                UnsavedChangesIndicator(
                  hasUnsavedChanges: true,
                  style: indicatorStyle,
                  size: 10,
                ),
              ],
            ],
          ),
        );
      }).toList(),
      controller: controller,
      isScrollable: isScrollable,
    );
  }
}