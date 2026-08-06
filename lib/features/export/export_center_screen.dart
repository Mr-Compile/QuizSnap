import 'package:flutter/material.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/app_bar.dart';
import '../../core/models/export.dart';
import 'export_options_screen.dart';
import 'backup_restore_screen.dart';

class ExportCenterScreen extends StatelessWidget {
  const ExportCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Export & Backup',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: 'Export',
            icon: Icons.ios_share,
            items: [
              _ExportMenuItem(
                title: 'Flashcards to PDF',
                description: 'Export flashcards as printable PDF document',
                icon: Icons.picture_as_pdf,
                color: Colors.red,
                onTap: () => _navigateToExportOptions(
                  context,
                  ExportType.flashcards,
                  ExportFormat.pdf,
                ),
              ),
              _ExportMenuItem(
                title: 'Quiz to PDF',
                description: 'Export quiz as printable PDF with questions',
                icon: Icons.quiz,
                color: Colors.blue,
                onTap: () => _navigateToExportOptions(
                  context,
                  ExportType.quiz,
                  ExportFormat.pdf,
                ),
              ),
              _ExportMenuItem(
                title: 'Answer Key',
                description: 'Export answer key separately',
                icon: Icons.check_circle,
                color: Colors.green,
                onTap: () => _navigateToExportOptions(
                  context,
                  ExportType.answerKey,
                  ExportFormat.pdf,
                ),
              ),
              _ExportMenuItem(
                title: 'Export to CSV',
                description: 'Export data as CSV spreadsheet',
                icon: Icons.table_chart,
                color: Colors.orange,
                onTap: () => _navigateToExportOptions(
                  context,
                  ExportType.flashcards,
                  ExportFormat.csv,
                ),
              ),
              _ExportMenuItem(
                title: 'Export to JSON',
                description: 'Export data as JSON backup',
                icon: Icons.code,
                color: Colors.purple,
                onTap: () => _navigateToExportOptions(
                  context,
                  ExportType.backup,
                  ExportFormat.json,
                ),
              ),
              _ExportMenuItem(
                title: 'Printable Study Pack',
                description: 'Complete printable study materials',
                icon: Icons.print,
                color: Colors.teal,
                onTap: () => _navigateToExportOptions(
                  context,
                  ExportType.studyPack,
                  ExportFormat.pdf,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'Backup',
            icon: Icons.backup,
            items: [
              _ExportMenuItem(
                title: 'Manual Backup',
                description: 'Create a full backup of your data',
                icon: Icons.save,
                color: Colors.indigo,
                onTap: () => _navigateToBackupRestore(context),
              ),
              _ExportMenuItem(
                title: 'Backup & Restore',
                description: 'Manage backups and restore data',
                icon: Icons.restore,
                color: Colors.cyan,
                onTap: () => _navigateToBackupRestore(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_ExportMenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  void _navigateToExportOptions(
    BuildContext context,
    ExportType type,
    ExportFormat format,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExportOptionsScreen(
          initialType: type,
          initialFormat: format,
        ),
      ),
    );
  }

  void _navigateToBackupRestore(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BackupRestoreScreen(),
      ),
    );
  }
}

class _ExportMenuItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExportMenuItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}