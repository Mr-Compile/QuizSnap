import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';

/// Appearance settings screen with Material 3 segmented control for
/// theme selection and a live color preview section.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Appearance',
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing4,
              vertical: AppTheme.spacing4,
            ),
            children: [
              _buildThemeSection(context, themeProvider),
              const SizedBox(height: AppTheme.spacing4),
              _buildColorPreviewSection(context),
              const SizedBox(height: AppTheme.spacing6),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Theme mode selector — Material 3 SegmentedButton
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildThemeSection(BuildContext context, ThemeProvider provider) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.bambooGreen600.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(Icons.palette_outlined,
                      color: AppTheme.bambooGreen600, size: 22),
                ),
                const SizedBox(width: AppTheme.spacing3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theme Mode', style: AppTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Choose how QuizSnap looks',
                        style: AppTheme.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing4),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.settings_brightness_outlined),
                    label: Text('System'),
                  ),
                ],
                selected: {provider.themeMode},
                onSelectionChanged: (selection) {
                  provider.setThemeMode(selection.first);
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacing3),
            Text(
              _getThemeModeDescription(provider.themeMode),
              style: AppTheme.bodySmall.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Always use the light theme regardless of system settings.';
      case ThemeMode.dark:
        return 'Always use the dark theme — easier on the eyes at night.';
      case ThemeMode.system:
        return 'Follow your device\'s system theme setting automatically.';
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Color preview section
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildColorPreviewSection(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(Icons.color_lens_outlined,
                      color: Theme.of(context).colorScheme.primary, size: 22),
                ),
                const SizedBox(width: AppTheme.spacing3),
                Text('Color Preview', style: AppTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppTheme.spacing4),
            _buildPreviewCard(
                context, 'Primary', AppTheme.bambooGreen600),
            const SizedBox(height: AppTheme.spacing3),
            _buildPreviewCard(
                context, 'Secondary', Theme.of(context).colorScheme.secondary),
            const SizedBox(height: AppTheme.spacing3),
            _buildPreviewCard(
                context, 'Error', Theme.of(context).colorScheme.error),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
          const SizedBox(width: AppTheme.spacing4),
          Expanded(
            child: Text(label, style: AppTheme.labelLarge.copyWith(color: color)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing2,
              vertical: AppTheme.spacing1,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            ),
            child: Text(
              '#${_colorToHex(color)}',
              style: AppTheme.labelSmall.copyWith(
                color: color,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  }
}
