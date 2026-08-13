import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/app_bar.dart';
import '../../core/models/export.dart';
import '../../core/services/dialog_service.dart';

class ExportSuccessScreen extends StatelessWidget {
  final ExportResult exportResult;

  const ExportSuccessScreen({
    super.key,
    required this.exportResult,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Export Successful',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Export Completed!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your file has been generated successfully',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    context,
                    'Format',
                    _formatDisplay,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    'Type',
                    _typeDisplay,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    'File Size',
                    exportResult.fileSizeDisplay,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    'Created',
                    _dateTimeDisplay,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Share File',
              icon: Icons.share,
              fullWidth: true,
              onPressed: () => _handleShare(context),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Done',
              isSecondary: true,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  String get _formatDisplay {
    switch (exportResult.options.format) {
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.json:
        return 'JSON';
    }
  }

  String get _typeDisplay {
    switch (exportResult.options.type) {
      case ExportType.flashcards:
        return 'Flashcards';
      case ExportType.quiz:
        return 'Quiz';
      case ExportType.answerKey:
        return 'Answer Key';
      case ExportType.studyPack:
        return 'Study Pack';
      case ExportType.backup:
        return 'Backup';
    }
  }

  String get _dateTimeDisplay {
    return '${exportResult.completedAt?.day}/${exportResult.completedAt?.month}/${exportResult.completedAt?.year} '
        '${exportResult.completedAt?.hour}:${exportResult.completedAt?.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleShare(BuildContext context) async {
    if (exportResult.filePath == null) return;

    try {
      await Share.shareXFiles([XFile(exportResult.filePath!)]);
    } catch (e) {
      if (context.mounted) {
        await DialogService.showError(context, 'Failed to share: $e');
      }
    }
  }
}