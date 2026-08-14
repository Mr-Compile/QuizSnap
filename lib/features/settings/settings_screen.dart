import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/ai_quota_provider.dart';
import '../../core/providers/security_provider.dart';
import '../../core/providers/groq_provider.dart';
import '../../core/navigation/app_routes.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';

/// Modernised Settings home screen with clear information architecture.
///
/// Sections are rendered as grouped cards with section titles, short
/// descriptions, and meaningful iconography.  Every tile routes to a
/// functional sub-screen — no dead-end navigation.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Settings',
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing4,
          vertical: AppTheme.spacing4,
        ),
        children: [
          _buildAiFeatures(context),
          const SizedBox(height: AppTheme.spacing4),
          _buildDataManagement(context),
          const SizedBox(height: AppTheme.spacing4),
          _buildSecurityPrivacy(context),
          const SizedBox(height: AppTheme.spacing4),
          _buildAppearance(context),
          const SizedBox(height: AppTheme.spacing4),
          _buildNotifications(context),
          const SizedBox(height: AppTheme.spacing4),
          _buildSupportAbout(context),
          const SizedBox(height: AppTheme.spacing6),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Section builder — grouped card with title + description + tiles
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required List<Widget> tiles,
  }) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacing2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacing4,
                AppTheme.spacing3,
                AppTheme.spacing4,
                AppTheme.spacing2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: AppTheme.spacing3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          description,
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
            ),
            const Divider(height: 1),
            ...tiles,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: AppTheme.bodyLarge),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
      minVerticalPadding: 14,
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing2,
        vertical: AppTheme.spacing1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTheme.labelSmall.copyWith(color: color),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  AI Features
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildAiFeatures(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'AI Features',
      description: 'API key, quota, and model settings',
      icon: Icons.psychology_outlined,
      iconColor: AppTheme.purple600,
      tiles: [
        Consumer<GroqProvider>(
          builder: (context, groqProvider, _) {
            return _buildSettingsTile(
              context: context,
              icon: Icons.api,
              title: 'API Configuration',
              subtitle: groqProvider.isInitialized
                  ? 'Groq API key configured'
                  : 'Configure your Groq API key',
              trailing: groqProvider.isInitialized
                  ? _buildStatusChip(context, 'Active', AppTheme.bambooGreen600)
                  : _buildStatusChip(
                      context, 'Not Set', AppTheme.orange600),
              onTap: () => GoRouter.of(context).push(AppRoutes.apiConfiguration),
            );
          },
        ),
        Consumer<AiQuotaProvider>(
          builder: (context, quotaProvider, _) {
            final status = quotaProvider.quotaStatus;
            return _buildSettingsTile(
              context: context,
              icon: Icons.data_usage_outlined,
              title: 'AI Usage',
              subtitle: status != null
                  ? '${status.remaining} / ${status.limit} requests remaining today'
                  : 'View your AI usage statistics',
              trailing: status != null && status.isLow
                  ? _buildStatusChip(context, 'Low', AppTheme.orange600)
                  : null,
              onTap: () => GoRouter.of(context).push(AppRoutes.aiUsage),
            );
          },
        ),
        _buildSettingsTile(
          context: context,
          icon: Icons.admin_panel_settings_outlined,
          title: 'Authorized Quota',
          subtitle: 'Manage quota with authorization password',
          onTap: () => GoRouter.of(context).push(AppRoutes.authorizedQuota),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Data Management
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDataManagement(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Data Management',
      description: 'Backups, database, and trash',
      icon: Icons.storage_outlined,
      iconColor: AppTheme.blue600,
      tiles: [
        _buildSettingsTile(
          context: context,
          icon: Icons.backup_outlined,
          title: 'Backup & Restore',
          subtitle: 'Create backups and restore your data',
          onTap: () =>
              GoRouter.of(context).push(AppRoutes.backupRestoreEnhanced),
        ),
        _buildSettingsTile(
          context: context,
          icon: Icons.history_outlined,
          title: 'Backup History',
          subtitle: 'View and manage previous backups',
          onTap: () => GoRouter.of(context).push(AppRoutes.backupHistory),
        ),
        _buildSettingsTile(
          context: context,
          icon: Icons.storage_outlined,
          title: 'Database Maintenance',
          subtitle: 'Check integrity and repair database',
          onTap: () =>
              GoRouter.of(context).push(AppRoutes.databaseMaintenance),
        ),
        _buildSettingsTile(
          context: context,
          icon: Icons.delete_outline,
          title: 'Trash',
          subtitle: 'Restore or permanently delete items',
          onTap: () => GoRouter.of(context).push(AppRoutes.trash),
        ),
        _buildSettingsTile(
          context: context,
          icon: Icons.delete_sweep_outlined,
          title: 'Trash Settings',
          subtitle: 'Auto-cleanup and trash management',
          onTap: () => GoRouter.of(context).push(AppRoutes.trashSettings),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Security & Privacy
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildSecurityPrivacy(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Security & Privacy',
      description: 'PIN lock, app lock, and data privacy',
      icon: Icons.security_outlined,
      iconColor: AppTheme.red600,
      tiles: [
        Consumer<SecurityProvider>(
          builder: (context, securityProvider, _) {
            return _buildSettingsTile(
              context: context,
              icon: Icons.lock_outline,
              title: 'Security',
              subtitle: securityProvider.isPinEnabled
                  ? 'PIN lock enabled'
                  : 'Set up PIN lock and API keys',
              trailing: securityProvider.isPinEnabled
                  ? _buildStatusChip(context, 'Enabled', AppTheme.bambooGreen600)
                  : _buildStatusChip(
                      context, 'Disabled', AppTheme.orange600),
              onTap: () => GoRouter.of(context).push(AppRoutes.security),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Appearance
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildAppearance(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Appearance',
      description: 'Theme, colors, and display options',
      icon: Icons.palette_outlined,
      iconColor: AppTheme.bambooGreen600,
      tiles: [
        _buildSettingsTile(
          context: context,
          icon: Icons.dark_mode_outlined,
          title: 'Theme',
          subtitle: 'Light, dark, or system theme',
          onTap: () => GoRouter.of(context).push(AppRoutes.appearance),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Notifications
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildNotifications(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Notifications',
      description: 'Study reminders and alerts',
      icon: Icons.notifications_outlined,
      iconColor: AppTheme.amber600,
      tiles: [
        _buildSettingsTile(
          context: context,
          icon: Icons.alarm_outlined,
          title: 'Study Reminders',
          subtitle: 'Configure study notification schedule',
          onTap: () => GoRouter.of(context).push(AppRoutes.reminderSettings),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Support & About
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildSupportAbout(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Support & About',
      description: 'App info and help',
      icon: Icons.info_outline,
      iconColor: Theme.of(context).colorScheme.primary,
      tiles: [
        _buildSettingsTile(
          context: context,
          icon: Icons.menu_book_outlined,
          title: 'User Manual',
          subtitle: 'Learn how to use QuizSnap',
          onTap: () => GoRouter.of(context).push(AppRoutes.userManual),
        ),
        _buildSettingsTile(
          context: context,
          icon: Icons.info_outline,
          title: 'About QuizSnap',
          subtitle: 'Version 1.0.0',
          trailing: const SizedBox.shrink(),
          onTap: () => _showAboutDialog(context),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About QuizSnap'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Version 1.0.0'),
              const SizedBox(height: 16),
              const Text(
                'QuizSnap is a powerful flashcard and study application designed to help you learn effectively.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Create and organize flashcards'),
              const Text('• AI-powered question generation'),
              const Text('• Spaced repetition learning'),
              const Text('• Study analytics and insights'),
              const Text('• Export and backup options'),
              const Text('• Secure PIN lock and biometrics'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
