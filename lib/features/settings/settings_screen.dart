import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/ai_quota_provider.dart';
import '../../core/navigation/app_routes.dart';
import '../../shared/widgets/app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Settings',
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'General',
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Appearance'),
                subtitle: const Text('Theme, colors, and display options'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  GoRouter.of(context).push(AppRoutes.appearance);
                },
              ),
            ],
          ),
          _buildSection(
            title: 'Security & Privacy',
            children: [
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Security'),
                subtitle: const Text('PIN lock and API keys'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  GoRouter.of(context).push(AppRoutes.security);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Study Reminders'),
                subtitle: const Text('Configure study notification schedule'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  GoRouter.of(context).push(AppRoutes.reminderSettings);
                },
              ),
            ],
          ),
          _buildSection(
            title: 'AI Features',
            children: [
              Consumer<AiQuotaProvider>(
                builder: (context, quotaProvider, _) {
                  final status = quotaProvider.quotaStatus;
                  return ListTile(
                    leading: const Icon(Icons.psychology_outlined),
                    title: const Text('AI Usage'),
                    subtitle: status != null 
                        ? Text('${status.remaining} / ${status.limit} requests remaining today')
                        : const Text('View your AI usage statistics'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      GoRouter.of(context).push(AppRoutes.aiUsage);
                    },
                  );
                },
              ),
            ],
          ),
          _buildSection(
            title: 'Data Management',
            children: [
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('Backup & Restore'),
                subtitle: const Text('Create backups and restore your data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  GoRouter.of(context).push(AppRoutes.backupRestoreEnhanced);
                },
              ),
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('Database Maintenance'),
                subtitle: const Text('Check integrity and repair database'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  GoRouter.of(context).push(AppRoutes.databaseMaintenance);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Trash'),
                subtitle: const Text('Restore or permanently delete items'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  GoRouter.of(context).push(AppRoutes.trash);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('Trash Settings'),
                subtitle: const Text('Auto-cleanup and trash management'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  GoRouter.of(context).push(AppRoutes.trashSettings);
                },
              ),
            ],
          ),
          _buildSection(
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About QuizSnap'),
                subtitle: const Text('Version 1.0.0'),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Text(
            title,
            style: AppTheme.labelLarge.copyWith(
              color: AppTheme.bambooGreen600,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About QuizSnap'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'QuizSnap is a powerful flashcard and study application designed to help you learn effectively.',
            ),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Create and organize flashcards'),
            Text('• AI-powered question generation'),
            Text('• Spaced repetition learning'),
            Text('• Study analytics and insights'),
            Text('• Export and backup options'),
            Text('• Secure PIN lock and biometrics'),
          ],
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
