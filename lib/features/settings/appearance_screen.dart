import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';

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
            children: [
              ListTile(
                title: const Text('Theme Mode'),
                subtitle: Text(_getThemeModeLabel(themeProvider.themeMode)),
                trailing: const Icon(Icons.chevron_right),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                subtitle: const Text('Always use light theme'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                subtitle: const Text('Always use dark theme'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                subtitle: const Text('Follow system theme'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Preview'),
                subtitle: const Text('See how the theme looks'),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  children: [
                    _buildPreviewCard(context, 'Primary Color', AppTheme.bambooGreen),
                    const SizedBox(height: AppTheme.spacingMd),
                    _buildPreviewCard(context, 'Secondary Color', Theme.of(context).colorScheme.secondary),
                    const SizedBox(height: AppTheme.spacingMd),
                    _buildPreviewCard(context, 'Error Color', Theme.of(context).colorScheme.error),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  Widget _buildPreviewCard(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color),
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
          const SizedBox(width: AppTheme.spacingMd),
          Text(
            label,
            style: AppTheme.labelLarge.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
