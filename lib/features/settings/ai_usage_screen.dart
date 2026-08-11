import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ai_quota_provider.dart';
import '../../core/services/ai_quota_service.dart';
import '../../shared/widgets/app_bar.dart';
import 'authorized_quota_screen.dart';

class AiUsageScreen extends StatefulWidget {
  const AiUsageScreen({super.key});

  @override
  State<AiUsageScreen> createState() => _AiUsageScreenState();
}

class _AiUsageScreenState extends State<AiUsageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'AI Usage',
      ),
      body: Consumer<AiQuotaProvider>(
        builder: (context, quotaProvider, _) {
          final status = quotaProvider.quotaStatus;
          
          if (status == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Quota overview card
              _buildQuotaOverview(context, status),
              const SizedBox(height: 24),
              
              // Quota details
              _buildQuotaDetails(context, status),
              const SizedBox(height: 24),
              
              // Authorized controls button
              Card(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Authorized Controls'),
                  subtitle: const Text('Manage quota with authorization'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthorizedQuotaScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Usage history
              _buildUsageHistorySection(context, quotaProvider),
              const SizedBox(height: 24),
              
              // Information
              _buildInformationSection(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuotaOverview(BuildContext context, QuotaStatus status) {
    final percentage = status.used / status.limit;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Quota',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status.isLow
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.displayText,
                    style: TextStyle(
                      color: status.isLow
                          ? Theme.of(context).colorScheme.onErrorContainer
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 12,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  status.isLow
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Status message
            Row(
              children: [
                Icon(
                  status.isLow ? Icons.warning : Icons.check_circle,
                  color: status.isLow
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: status.isLow
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaDetails(BuildContext context, QuotaStatus status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(
                  context,
                  label: 'Used',
                  value: status.used.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _buildDetailItem(
                  context,
                  label: 'Remaining',
                  value: status.remaining.toString(),
                  icon: Icons.hourglass_empty,
                  color: status.isLow ? Colors.red : Theme.of(context).colorScheme.primary,
                ),
                _buildDetailItem(
                  context,
                  label: 'Limit',
                  value: status.limit.toString(),
                  icon: Icons.speed,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildUsageHistorySection(BuildContext context, AiQuotaProvider quotaProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Usage History',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => quotaProvider.refreshQuota(),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            FutureBuilder(
              future: quotaProvider.service.getUsageHistory(days: 7),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                
                final history = snapshot.data ?? [];
                
                if (history.isEmpty) {
                  return const Center(
                    child: Text('No usage history available'),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final usage = history[index];
                    return _buildHistoryItem(context, usage);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, dynamic usage) {
    // Assuming usage has date, usedCount, dailyLimit properties
    final date = DateTime.tryParse(usage.date.toString()) ?? DateTime.now();
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    final usedCount = usage.usedCount as int? ?? 0;
    final dailyLimit = usage.dailyLimit as int? ?? 15;
    final percentage = usedCount / dailyLimit;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              formattedDate,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage >= 1.0
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              '$usedCount/$dailyLimit',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'About AI Quota',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Each AI generation consumes 1 quota request',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '• Quota resets automatically at 12:00 AM local time',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '• Failed requests do not consume quota',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '• Regenerating questions also consumes quota',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}