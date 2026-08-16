import 'dart:io';
import 'package:flutter/material.dart';
import '../../shared/widgets/app_bar.dart';
import 'package:provider/provider.dart';
import 'package:pdfx/pdfx.dart';
import '../../core/services/document_extraction_service.dart';
import '../../core/services/document_cache_service.dart';
import '../../core/services/cached_document_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/dialog_service.dart';
import 'analysis_preview_screen.dart';

class DocumentHeading {
  final String title;
  final int startPage;
  int endPage;
  final int level; // 1 for main heading, 2 for subheading, etc.
  bool isSelected;

  DocumentHeading({
    required this.title,
    required this.startPage,
    required this.endPage,
    this.level = 1,
    this.isSelected = false,
  });
}

class HeadingSelectionScreen extends StatefulWidget {
  final File file;

  const HeadingSelectionScreen({
    super.key,
    required this.file,
  });

  @override
  State<HeadingSelectionScreen> createState() => _HeadingSelectionScreenState();
}

class _HeadingSelectionScreenState extends State<HeadingSelectionScreen> {
  bool _isLoading = true;
  bool _isExtracting = false;
  String? _errorMessage;
  List<DocumentHeading> _headings = [];
  int _totalPages = 0;
  PdfController? _pdfController;

  @override
  void initState() {
    super.initState();
    _loadPdfAndExtractHeadings();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadPdfAndExtractHeadings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = await widget.file.readAsBytes();
      _pdfController = PdfController(
        document: PdfDocument.openData(bytes),
      );
      
      // Get page count
      final pdfDocument = await _pdfController!.document;
      final pageCount = pdfDocument.pagesCount;
      
      setState(() {
        _totalPages = pageCount;
      });

      // Extract headings from PDF
      await _extractHeadings();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load PDF: $e';
      });
    }
  }

  Future<void> _extractHeadings() async {
    final headings = <DocumentHeading>[];
    
    try {
      // Extract text from the PDF
      final text = await DocumentExtractionService.extractFromPdf(widget.file);
      
      // Simple heading detection - look for common patterns
      // This is a basic implementation; for production, you might want to use
      // a more sophisticated PDF parsing library or AI-based heading detection
      final lines = text.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        
        // Skip empty lines
        if (line.isEmpty) continue;
        
        // Detect potential headings based on common patterns
        // 1. All caps
        // 2. Numbered sections (1., 2., etc.)
        // 3. Short lines that might be titles
        if (line.length < 100 && 
            (line == line.toUpperCase() || 
             RegExp(r'^\d+\.\s').hasMatch(line) ||
             RegExp(r'^Chapter\s+\d+').hasMatch(line) ||
             RegExp(r'^Section\s+\d+').hasMatch(line))) {
          
          // Create a heading (assigning page 1 as placeholder since pdfx doesn't provide page-level text extraction)
          headings.add(DocumentHeading(
            title: line,
            startPage: 1,
            endPage: _totalPages,
            level: 1,
          ));
        }
      }
      
      // If no headings found, create a default one for the entire document
      if (headings.isEmpty) {
        headings.add(DocumentHeading(
          title: 'Full Document',
          startPage: 1,
          endPage: _totalPages,
          level: 1,
        ));
      }
      
      setState(() {
        _headings = headings;
      });
    } catch (e) {
      // If heading extraction fails, create a default heading
      setState(() {
        _headings = [
          DocumentHeading(
            title: 'Full Document',
            startPage: 1,
            endPage: _totalPages,
            level: 1,
          ),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Select Chapters/Headings',
        actions: [
          if (_headings.any((h) => h.isSelected))
            TextButton.icon(
              onPressed: _isExtracting ? null : _extractSelectedHeadings,
              icon: _isExtracting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: _isExtracting
                  ? const Text('Extracting...')
                  : Text('Extract (${_headings.where((h) => h.isSelected).length})'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _headings.isEmpty
                  ? _buildEmptyState()
                  : _buildHeadingList(),
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
            'Failed to load PDF',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.format_list_bulleted,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No headings found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This PDF may not have detectable chapter/heading structure',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Page Selection Instead'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadingList() {
    return Column(
      children: [
        // Selection controls
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Checkbox(
                value: _headings.every((h) => h.isSelected),
                onChanged: (value) {
                  setState(() {
                    for (final heading in _headings) {
                      heading.isSelected = value ?? false;
                    }
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _headings.every((h) => h.isSelected)
                      ? 'All headings selected'
                      : '${_headings.where((h) => h.isSelected).length} of ${_headings.length} selected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (_headings.any((h) => h.isSelected))
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (final heading in _headings) {
                        heading.isSelected = false;
                      }
                    });
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),
        // Heading list
        Expanded(
          child: Row(
            children: [
              // PDF Viewer (left side)
              Expanded(
                flex: 1,
                child: _pdfController != null
                    ? PdfView(
                        controller: _pdfController!,
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
              // Heading list (right side)
              Expanded(
                flex: 1,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _headings.length,
                  itemBuilder: (context, index) {
                    final heading = _headings[index];
                    return _buildHeadingTile(heading, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeadingTile(DocumentHeading heading, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: heading.isSelected,
        onChanged: (value) {
          setState(() {
            heading.isSelected = value ?? false;
          });
        },
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heading.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pages ${heading.startPage}-${heading.endPage}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: _buildHeadingLevelIndicator(heading.level),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildHeadingLevelIndicator(int level) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
    ];
    
    final labels = ['Main', 'Sub', 'Sub-sub'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors[(level - 1) % colors.length].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        labels[(level - 1) % labels.length],
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors[(level - 1) % colors.length],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _extractSelectedHeadings() async {
    final selectedHeadings = _headings.where((h) => h.isSelected).toList();
    if (selectedHeadings.isEmpty) return;

    setState(() {
      _isExtracting = true;
    });

    try {
      // Collect all pages from selected headings
      final pages = <int>[];
      final headingNames = <String>[];
      for (final heading in selectedHeadings) {
        for (int page = heading.startPage; page <= heading.endPage; page++) {
          if (!pages.contains(page)) {
            pages.add(page);
          }
        }
        headingNames.add(heading.title);
      }

      pages.sort();

      // Extract text from selected pages
      final text = await DocumentExtractionService.extractFromPdf(
        widget.file,
        pages: pages,
      );

      if (!mounted) return;

      // Cache the extracted document
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final cacheService = CachedDocumentService(DocumentCacheService(dbProvider));

      await cacheService.cacheDocument(
        fileName: widget.file.path.split('/').last,
        filePath: widget.file.path,
        rawText: text,
        selectedScope: 'headings',
        totalPages: _totalPages,
        source: 'PDF sections',
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AnalysisPreviewScreen(
            text: text,
            source: 'PDF sections',
            scopeType: 'headings',
            scopeDetails: {
              'headings': headingNames,
              'pages': pages,
              'characterCount': text.length,
            },
            totalPages: _totalPages,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isExtracting = false;
      });

      DialogService.showError(context, 'Failed to extract text: $e');
    }
  }
}