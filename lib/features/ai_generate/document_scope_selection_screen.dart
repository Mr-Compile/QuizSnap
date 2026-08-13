import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/document_extraction_service.dart';
import '../../core/services/document_cache_service.dart';
import '../../core/services/cached_document_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/stepper_header.dart';
import 'page_range_selector_screen.dart';
import 'heading_tree_selection_screen.dart';
import 'text_highlight_selection_screen.dart';
import 'analysis_preview_screen.dart';

enum DocumentScope {
  entireDocument,
  specificPages,
  byHeadings,
  highlightedText,
}

class DocumentScopeSelectionScreen extends StatefulWidget {
  final File file;
  final String fileType;

  const DocumentScopeSelectionScreen({
    super.key,
    required this.file,
    required this.fileType,
  });

  @override
  State<DocumentScopeSelectionScreen> createState() => _DocumentScopeSelectionScreenState();
}

class _DocumentScopeSelectionScreenState extends State<DocumentScopeSelectionScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  int? _totalPages;

  @override
  void initState() {
    super.initState();
    _loadDocumentInfo();
  }

  Future<void> _loadDocumentInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.fileType == 'pdf') {
        final pageCount = await DocumentExtractionService.getPageCount(widget.file);
        setState(() {
          _totalPages = pageCount;
          _isLoading = false;
        });
      } else {
        setState(() {
          _totalPages = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load document: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Document Scope'),
      ),
      body: Column(
        children: [
          const StepperHeader(
            currentStep: 1,
            steps: ['Import', 'Scope', 'Select', 'Preview', 'Generate'],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildScopeOptions(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load document',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeOptions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document info
          _buildDocumentInfo(),
          const SizedBox(height: 24),
          
          // Scope options
          Text(
            'Select what to analyze',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose which part of the document to use for question generation',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          
          // Scope option cards
          _buildScopeCard(
            context,
            title: 'Entire Document',
            description: 'Analyze all pages from the document',
            icon: Icons.description,
            color: Theme.of(context).colorScheme.secondary,
            onTap: () => _analyzeEntireDocument(),
          ),
          const SizedBox(height: 16),
          
          if (widget.fileType == 'pdf')
            _buildScopeCard(
              context,
              title: 'Specific Pages',
              description: 'Select specific page ranges to analyze',
              icon: Icons.pageview,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => _navigateToPageSelector(),
            ),
          
          if (widget.fileType == 'pdf')
            const SizedBox(height: 16),
          
          if (widget.fileType == 'pdf')
            _buildScopeCard(
              context,
              title: 'By Chapter/Heading',
              description: 'Select chapters or headings to analyze',
              icon: Icons.format_list_bulleted,
              color: Theme.of(context).colorScheme.tertiary,
              onTap: () => _navigateToHeadingSelector(),
            ),
          
          if (widget.fileType == 'pdf')
            const SizedBox(height: 16),
          
          _buildScopeCard(
            context,
            title: 'Highlighted Text',
            description: 'Select specific text from the document',
            icon: Icons.highlight,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            onTap: () => _navigateToHighlightSelector(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getFileIcon(),
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.file.path.split('/').last,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.fileType.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_totalPages != null && _totalPages! > 1) ...[
            const SizedBox(height: 12),
            Text(
              '$_totalPages pages',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    switch (widget.fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
        return Icons.text_snippet;
      case 'docx':
        return Icons.description;
      default:
        return Icons.description;
    }
  }

  Widget _buildScopeCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
  }

  Future<void> _analyzeEntireDocument() async {
    try {
      final rawText = await DocumentExtractionService.extractFromFile(widget.file);

      if (!mounted) return;

      // Cache the extracted document with raw/cleaned versions and sections.
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final cacheService = CachedDocumentService(DocumentCacheService(dbProvider));

      await cacheService.cacheDocument(
        fileName: widget.file.path.split('/').last,
        filePath: widget.file.path,
        rawText: rawText,
        selectedScope: 'all',
        totalPages: _totalPages,
        source: 'Entire ${widget.fileType.toUpperCase()}',
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AnalysisPreviewScreen(
            text: rawText,
            source: 'Entire ${widget.fileType.toUpperCase()}',
            scopeType: 'all',
            scopeDetails: const {},
            totalPages: _totalPages ?? 0,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      DialogService.showError(context, 'Failed to extract text: $e');
    }
  }

  void _navigateToPageSelector() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PageRangeSelectorScreen(file: widget.file),
      ),
    );
  }

  void _navigateToHeadingSelector() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HeadingTreeSelectionScreen(file: widget.file),
      ),
    );
  }

  void _navigateToHighlightSelector() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TextHighlightSelectionScreen(
          file: widget.file,
          fileType: widget.fileType,
        ),
      ),
    );
  }
}