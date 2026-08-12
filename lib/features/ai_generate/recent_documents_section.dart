import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/cached_document_service.dart';
import '../../core/services/document_cache_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import 'cached_document_details_screen.dart';

/// Lists recently-cached imported documents on the AI home screen.
class RecentDocumentsSection extends StatelessWidget {
  const RecentDocumentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseProvider>();
    final service = CachedDocumentService(DocumentCacheService(db));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Documents',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        FutureBuilder(
          future: service.getAllCachedDocuments(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data ?? [];
            if (docs.isEmpty) {
              return const EmptyState(
                icon: Icons.folder_open,
                title: 'No cached documents',
                subtitle: 'Import a document to see it here and reopen it offline',
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                return CustomCard(
                  onTap: () => _openDetails(context, doc.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        _iconForScope(doc.selectedScope),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.displayName,
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${doc.totalPages} pages • ${doc.cleanedText.length} chars',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  IconData _iconForScope(String scope) {
    switch (scope) {
      case 'pdf':
      case 'pages':
        return Icons.picture_as_pdf;
      case 'docx':
      case 'headings':
        return Icons.description;
      case 'txt':
      case 'all':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _openDetails(BuildContext context, int id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CachedDocumentDetailsScreen(documentId: id),
      ),
    );
  }
}
