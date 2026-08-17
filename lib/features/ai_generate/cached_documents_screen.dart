import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/document_import_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'cached_document_details_screen.dart';
import '../../core/services/dialog_service.dart';

class CachedDocumentsScreen extends StatefulWidget {
  const CachedDocumentsScreen({super.key});

  @override
  State<CachedDocumentsScreen> createState() => _CachedDocumentsScreenState();
}

class _CachedDocumentsScreenState extends State<CachedDocumentsScreen> {
  final DocumentImportService _importService = DocumentImportService(
    DatabaseProvider(),
  );

  @override
  void initState() {
    super.initState();
    _loadCachedDocuments();
  }

  Future<void> _loadCachedDocuments() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Cached Documents',
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder(
            future: _importService.getAllCachedDocuments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading documents',
                        style: AppTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: AppTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final documents = snapshot.data ?? [];

              if (documents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No cached documents',
                        style: AppTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Import documents to see them here',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  return _buildDocumentCard(context, doc, dbProvider);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, ImportResult doc, DatabaseProvider dbProvider) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: InkWell(
        onTap: () {
          if (doc.id != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CachedDocumentDetailsScreen(documentId: doc.id!),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: _getDocumentTypeColor(doc.documentType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    _getDocumentTypeIcon(doc.documentType),
                    color: _getDocumentTypeColor(doc.documentType),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.filePath?.split('/').last ?? 'Unknown Document',
                        style: AppTheme.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        _getDocumentTypeLabel(doc.documentType),
                        style: AppTheme.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showDeleteDialog(context, doc),
                ),
              ],
            ),
            if (doc.totalPages != null && doc.totalPages! > 0) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                children: [
                  Icon(
                    Icons.description,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    '${doc.totalPages} pages',
                    style: AppTheme.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getDocumentTypeColor(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return Theme.of(context).colorScheme.error;
      case DocumentType.txt:
        return Theme.of(context).colorScheme.primary;
      case DocumentType.docx:
        return Theme.of(context).colorScheme.secondary;
      case DocumentType.pptx:
        return const Color(0xFFF97316); // Orange
      case DocumentType.ppt:
        return const Color(0xFFEA580C); // Dark Orange
    }
  }

  IconData _getDocumentTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return Icons.picture_as_pdf;
      case DocumentType.txt:
        return Icons.text_snippet;
      case DocumentType.docx:
        return Icons.description;
      case DocumentType.pptx:
        return Icons.slideshow;
      case DocumentType.ppt:
        return Icons.slideshow_outlined;
    }
  }

  String _getDocumentTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return 'PDF Document';
      case DocumentType.txt:
        return 'Text File';
      case DocumentType.docx:
        return 'Word Document';
      case DocumentType.pptx:
        return 'PowerPoint (PPTX)';
      case DocumentType.ppt:
        return 'PowerPoint (PPT)';
    }
  }

  void _showDeleteDialog(BuildContext context, ImportResult doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this cached document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Note: We need the document ID to delete it
              // For now, just show a message
              await DialogService.showWarning(context, 'Delete functionality needs document ID');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
