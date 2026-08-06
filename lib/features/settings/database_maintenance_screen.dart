import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/database_maintenance_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';

class DatabaseMaintenanceScreen extends StatefulWidget {
  const DatabaseMaintenanceScreen({super.key});

  @override
  State<DatabaseMaintenanceScreen> createState() => _DatabaseMaintenanceScreenState();
}

class _DatabaseMaintenanceScreenState extends State<DatabaseMaintenanceScreen> {
  DatabaseIntegrityReport? _integrityReport;
  DatabaseStats? _stats;
  MaintenanceResult? _maintenanceResult;
  bool _isChecking = false;
  bool _isRepairing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _checkIntegrity();
    await _loadStats();
  }

  Future<void> _checkIntegrity() async {
    setState(() {
      _isChecking = true;
    });

    final dbProvider = context.read<DatabaseProvider>();
    final maintenanceService = DatabaseMaintenanceService(dbProvider.database);
    
    final report = await maintenanceService.checkIntegrity();

    if (!mounted) return;

    setState(() {
      _integrityReport = report;
      _isChecking = false;
    });
  }

  Future<void> _loadStats() async {
    final dbProvider = context.read<DatabaseProvider>();
    final maintenanceService = DatabaseMaintenanceService(dbProvider.database);
    
    final stats = await maintenanceService.getDatabaseStats();

    if (!mounted) return;

    setState(() {
      _stats = stats;
    });
  }

  Future<void> _repairDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repair Database'),
        content: const Text(
          'This will:\n'
          '• Fix orphaned deck references\n'
          '• Delete orphaned flashcards\n'
          '• Remove unused tags\n'
          '• Fix invalid ease factors\n'
          '• Recalculate deck counts\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Repair'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRepairing = true;
    });

    final dbProvider = context.read<DatabaseProvider>();
    final maintenanceService = DatabaseMaintenanceService(dbProvider.database);
    
    final result = await maintenanceService.repairDatabase();

    if (!mounted) return;

    setState(() {
      _maintenanceResult = result;
      _isRepairing = false;
    });

    // Reload data after repair
    await _loadData();

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database repaired successfully: ${result.toString()}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Repair failed: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Database Maintenance',
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        children: [
          _buildIntegrityCard(),
          const SizedBox(height: AppTheme.spacingLg),
          _buildStatsCard(),
          const SizedBox(height: AppTheme.spacingLg),
          _buildActionsCard(),
          const SizedBox(height: AppTheme.spacingLg),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildIntegrityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Database Integrity',
                  style: AppTheme.titleMedium,
                ),
                if (_isChecking)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_integrityReport != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm,
                      vertical: AppTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: _integrityReport!.isHealthy 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: _integrityReport!.isHealthy ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _integrityReport!.isHealthy ? Icons.check_circle : Icons.warning,
                          color: _integrityReport!.isHealthy ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _integrityReport!.isHealthy ? 'Healthy' : 'Issues Found',
                          style: AppTheme.labelSmall.copyWith(
                            color: _integrityReport!.isHealthy ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (_integrityReport != null) ...[
              _buildIntegrityItem('Folders', _integrityReport!.folderCount.toString()),
              _buildIntegrityItem('Orphaned Decks', _integrityReport!.orphanedDecks.toString()),
              _buildIntegrityItem('Orphaned Flashcards', _integrityReport!.orphanedFlashcards.toString()),
              _buildIntegrityItem('Orphaned Tags', _integrityReport!.orphanedTags.toString()),
              _buildIntegrityItem('Orphaned Flashcard Tags', _integrityReport!.orphanedFlashcardTags.toString()),
              _buildIntegrityItem('Invalid Review Dates', _integrityReport!.invalidReviewDates.toString()),
              _buildIntegrityItem('Invalid Ease Factors', _integrityReport!.invalidEaseFactors.toString()),
              if (_integrityReport!.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingMd),
                  child: Text(
                    'Error: ${_integrityReport!.error}',
                    style: AppTheme.bodySmall.copyWith(color: Colors.red),
                  ),
                ),
            ],
            const SizedBox(height: AppTheme.spacingMd),
            CustomButton(
              text: 'Recheck Integrity',
              onPressed: _isChecking ? null : _checkIntegrity,
              isOutlined: true,
              isLoading: _isChecking,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrityItem(String label, String value) {
    final hasIssue = int.tryParse(value) != null && int.parse(value) > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              color: hasIssue ? Colors.orange : null,
              fontWeight: hasIssue ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Statistics',
              style: AppTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (_stats != null) ...[
              _buildStatItem('Folders', _stats!.folderCount.toString()),
              _buildStatItem('Decks', _stats!.deckCount.toString()),
              _buildStatItem('Flashcards', _stats!.flashcardCount.toString()),
              _buildStatItem('Tags', _stats!.tagCount.toString()),
              _buildStatItem('Study Sessions', _stats!.studySessionCount.toString()),
              _buildStatItem('Quiz Results', _stats!.quizResultCount.toString()),
              _buildStatItem('Total Study Time', _stats!.totalStudyTimeFormatted),
              _buildStatItem('Average Quiz Score', '${(_stats!.averageQuizScore * 100).toStringAsFixed(1)}%'),
              if (_stats!.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingMd),
                  child: Text(
                    'Error: ${_stats!.error}',
                    style: AppTheme.bodySmall.copyWith(color: Colors.red),
                  ),
                ),
            ] else
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium),
          Text(value, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maintenance Actions',
              style: AppTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            CustomButton(
              text: 'Repair Database',
              onPressed: _isRepairing ? null : _repairDatabase,
              isLoading: _isRepairing,
            ),
            if (_maintenanceResult != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: _maintenanceResult!.success 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: _maintenanceResult!.success ? Colors.green : Colors.red,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _maintenanceResult!.success ? 'Repair Completed' : 'Repair Failed',
                      style: AppTheme.labelMedium.copyWith(
                        color: _maintenanceResult!.success ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    if (_maintenanceResult!.success) ...[
                      Text('Fixed orphaned decks: ${_maintenanceResult!.fixedOrphanedDecks}'),
                      Text('Deleted orphaned flashcards: ${_maintenanceResult!.deletedOrphanedFlashcards}'),
                      Text('Deleted orphaned tags: ${_maintenanceResult!.deletedOrphanedTags}'),
                      Text('Deleted orphaned flashcard tags: ${_maintenanceResult!.deletedOrphanedFlashcardTags}'),
                      Text('Fixed ease factors: ${_maintenanceResult!.fixedEaseFactors}'),
                      Text('Recalculated deck counts: ${_maintenanceResult!.recalculatedDeckCounts}'),
                    ] else if (_maintenanceResult!.error != null)
                      Text('Error: ${_maintenanceResult!.error}'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Database Maintenance',
              style: AppTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildInfoItem(
              icon: Icons.check_circle_outline,
              title: 'Integrity Check',
              description: 'Scans for orphaned records, invalid data, and structural issues',
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildInfoItem(
              icon: Icons.build,
              title: 'Repair',
              description: 'Automatically fixes common database issues and optimizes structure',
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildInfoItem(
              icon: Icons.bar_chart,
              title: 'Statistics',
              description: 'View detailed information about your database content and usage',
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildInfoItem(
              icon: Icons.info_outline,
              title: 'Regular Maintenance',
              description: 'Run integrity checks periodically to ensure optimal performance',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.bambooGreen600, size: 20),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.labelMedium,
              ),
              Text(
                description,
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
