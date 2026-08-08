import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/services/document_extraction_service.dart';
import '../../core/services/document_cache_service.dart';
import '../../core/providers/database_provider.dart';
import 'text_preview_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPdfAndExtractHeadings();
  }

  Future<void> _loadPdfAndExtractHeadings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = await widget.file.readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      
      setState(() {
        _totalPages = doc.pages.count;
      });

      // Extract headings from PDF
      await _extractHeadings(doc);
      
      doc.dispose();
      
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

  Future<void> _extractHeadings(PdfDocument doc) async {
    final headings = <DocumentHeading>[];
    
    // Simple heading detection - look for larger text and common patterns
    for (int i = 0; i < doc.pages.count; i++) {
      final textExtractor = PdfTextExtractor(doc);
      final text = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
      
      // Look for heading patterns (lines that are all caps, start with numbers, etc.)
      final lines = text.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (_isLikelyHeading(trimmed)) {
          headings.add(DocumentHeading(
            title: trimmed,
            startPage: i + 1,
            endPage: i + 1, // Will be updated later
            level: _getHeadingLevel(trimmed),
          ));
        }
      }
    }

    // Update end pages for headings
    for (int i = 0; i < headings.length; i++) {
      if (i < headings.length - 1) {
        headings[i].endPage = headings[i + 1].startPage - 1;
      } else {
        headings[i].endPage = _totalPages;
      }
    }

    setState(() {
      _headings = headings;
    });
  }

  bool _isLikelyHeading(String text) {
    if (text.length < 3) return false;
    if (text.length > 100) return false;
    
    // Check for common heading patterns
    final patterns = [
      RegExp(r'^Chapter \d+', caseSensitive: false),
      RegExp(r'^\d+\.\s', caseSensitive: false), // "1. Introduction"
      RegExp(r'^[A-Z][A-Z\s]+$'), // All caps
      RegExp(r'^Section \d+', caseSensitive: false),
      RegExp(r'^Part [IVX]+', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      if (pattern.hasMatch(text)) return true;
    }

    // Check if first letter is capitalized and rest are not all lowercase
    if (text[0] == text[0].toUpperCase() && 
        !text.substring(1).contains(RegExp(r'[A-Z]'))) {
      return true;
    }

    return false;
  }

  int _getHeadingLevel(String text) {
    // Determine heading level based on patterns
    if (RegExp(r'^Chapter \d+', caseSensitive: false).hasMatch(text)) return 1;
    if (RegExp(r'^Part [IVX]+', caseSensitive: false).hasMatch(text)) return 1;
    if (RegExp(r'^Section \d+', caseSensitive: false).hasMatch(text)) return 2;
    if (RegExp(r'^\d+\.\d+\.', caseSensitive: false).hasMatch(text)) return 3; // "1.1. Introduction"
    if (RegExp(r'^\d+\.', caseSensitive: false).hasMatch(text)) return 2;
    
    return 2; // Default level
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Chapters/Headings'),
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
      final cacheService = DocumentCacheService(dbProvider);
      
      await cacheService.cacheDocument(
        fileName: widget.file.path.split('/').last,
        filePath: widget.file.path,
        extractedText: text,
        selectedScope: 'headings',
        scopeDetails: {
          'headings': headingNames,
          'pages': pages,
        },
        totalPages: _totalPages,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TextPreviewScreen(
            text: text,
            source: 'PDF (${selectedHeadings.length} sections)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isExtracting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to extract text: $e')),
      );
    }
  }
}