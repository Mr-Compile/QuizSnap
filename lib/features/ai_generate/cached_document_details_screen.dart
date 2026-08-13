import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../core/services/cached_document_service.dart';
import '../../core/services/document_cache_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import 'analysis_preview_screen.dart';
import 'heading_tree_selection_screen.dart';

/// Details for a cached (offline) imported document.
class CachedDocumentDetailsScreen extends StatefulWidget {
  final int documentId;

  const CachedDocumentDetailsScreen({super.key, required this.documentId});

  @override
  State<CachedDocumentDetailsScreen> createState() => _CachedDocumentDetailsScreenState();
}

class _CachedDocumentDetailsScreenState extends State<CachedDocumentDetailsScreen> {
  late final CachedDocumentService _service;

  @override
  void initState() {
    super.initState();
    final db = context.read<DatabaseProvider>();
    _service = CachedDocumentService(DocumentCacheService(db));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Document Details'),
      body: FutureBuilder(
        future: _service.getCachedDocument(widget.documentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Document not found',
              subtitle: snapshot.error?.toString() ?? '',
            );
          }

          final doc = snapshot.data!;
          final fmt = DateFormat.yMd().add_jm();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.displayName, style: AppTheme.titleLarge),
                      const SizedBox(height: AppTheme.spacingSm),
                      _buildInfoRow('Pages', '${doc.totalPages}'),
                      _buildInfoRow('Imported', doc.createdAt != null ? fmt.format(doc.createdAt!) : 'N/A'),
                      _buildInfoRow('Last used', doc.lastUsedAt != null ? fmt.format(doc.lastUsedAt!) : 'N/A'),
                      _buildInfoRow('Scope', doc.selectedScope),
                      _buildInfoRow('Characters', '${doc.cleanedText.length}'),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                CustomButton(
                  text: 'Analyze Entire Document',
                  icon: Icons.description,
                  fullWidth: true,
                  onPressed: () => _preview(context, doc.cleanedText, 'all'),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                CustomButton(
                  text: 'Choose Sections',
                  icon: Icons.format_list_bulleted,
                  fullWidth: true,
                  onPressed: () => _openSections(context, doc),
                  isSecondary: true,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                CustomButton(
                  text: 'Delete Cache',
                  icon: Icons.delete_outline,
                  fullWidth: true,
                  onPressed: () => _delete(context),
                  isOutlined: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  void _openSections(BuildContext context, CachedDocument doc) {
    final file = File(doc.filePath);
    if (!file.existsSync()) {
      DialogService.showError(context, 'Original file not found');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HeadingTreeSelectionScreen(file: file),
      ),
    );
  }

  void _preview(BuildContext context, String text, String scopeType) {
    if (text.trim().isEmpty) {
      DialogService.showError(context, 'No content available');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnalysisPreviewScreen(
          text: text,
          source: 'Cached document',
          scopeType: scopeType,
          scopeDetails: const {},
          totalPages: 0,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete cached document?'),
        content: const Text('This will remove the file and cached text.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _service.deleteCachedDocument(widget.documentId);
      if (context.mounted) {
        DialogService.showSuccess(context, 'Document deleted');
        Navigator.of(context).pop();
      }
    }
  }
}
