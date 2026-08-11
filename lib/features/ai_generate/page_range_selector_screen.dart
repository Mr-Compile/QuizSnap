import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfx/pdfx.dart';
import '../../core/services/document_extraction_service.dart';
import '../../core/services/document_cache_service.dart';
import '../../core/providers/database_provider.dart';
import 'text_preview_screen.dart';

class PageRangeSelectorScreen extends StatefulWidget {
  final File file;

  const PageRangeSelectorScreen({
    super.key,
    required this.file,
  });

  @override
  State<PageRangeSelectorScreen> createState() => _PageRangeSelectorScreenState();
}

class _PageRangeSelectorScreenState extends State<PageRangeSelectorScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  int _totalPages = 0;
  final TextEditingController _rangeController = TextEditingController();
  final Set<int> _selectedPages = {};
  List<List<int>> _parsedRanges = [];
  PdfController? _pdfController;

  @override
  void initState() {
    super.initState();
    _loadPdfInfo();
  }

  @override
  void dispose() {
    _rangeController.dispose();
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadPdfInfo() async {
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load PDF: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Page Range'),
        actions: [
          if (_selectedPages.isNotEmpty)
            TextButton.icon(
              onPressed: _selectedPages.isEmpty ? null : _extractText,
              icon: const Icon(Icons.check),
              label: Text('Extract (${_selectedPages.length})'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildPageSelector(),
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

  Widget _buildPageSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document info
          _buildDocumentInfo(),
          const SizedBox(height: 24),
          
          // Range input
          _buildRangeInput(),
          const SizedBox(height: 24),
          
          // Page grid
          _buildPageGrid(),
          const SizedBox(height: 24),
          
          // Selection summary
          _buildSelectionSummary(),
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
      child: Row(
        children: [
          Icon(
            Icons.picture_as_pdf,
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
                  '$_totalPages pages total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Page Ranges',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Examples: 1, 3-5, 10-12, 20',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _rangeController,
          decoration: InputDecoration(
            hintText: 'e.g., 1-5, 10, 15-20',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _rangeController.clear();
                _selectedPages.clear();
                _parsedRanges.clear();
                setState(() {});
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _parseAndSelectRanges,
                icon: const Icon(Icons.check),
                label: const Text('Apply Ranges'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectAllPages,
                icon: const Icon(Icons.select_all),
                label: const Text('Select All'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPageGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Pages',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_selectedPages.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedPages.clear();
                    _rangeController.clear();
                    _parsedRanges.clear();
                  });
                },
                child: const Text('Clear Selection'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _totalPages,
          itemBuilder: (context, index) {
            final pageNumber = index + 1;
            final isSelected = _selectedPages.contains(pageNumber);
            
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedPages.remove(pageNumber);
                  } else {
                    _selectedPages.add(pageNumber);
                  }
                  _updateRangeText();
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Center(
                  child: Text(
                    pageNumber.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectionSummary() {
    if (_selectedPages.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedPages = _selectedPages.toList()..sort();
    final rangeText = _formatPageRanges(sortedPages);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${_selectedPages.length} pages selected',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rangeText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  void _parseAndSelectRanges() {
    final input = _rangeController.text.trim();
    if (input.isEmpty) return;

    final newSelection = <int>{};
    final ranges = input.split(',');

    for (final range in ranges) {
      final trimmed = range.trim();
      if (trimmed.contains('-')) {
        final parts = trimmed.split('-');
        if (parts.length == 2) {
          final start = int.tryParse(parts[0].trim());
          final end = int.tryParse(parts[1].trim());
          if (start != null && end != null && start <= end) {
            for (int i = start; i <= end; i++) {
              if (i >= 1 && i <= _totalPages) {
                newSelection.add(i);
              }
            }
          }
        }
      } else {
        final page = int.tryParse(trimmed);
        if (page != null && page >= 1 && page <= _totalPages) {
          newSelection.add(page);
        }
      }
    }

    setState(() {
      _selectedPages.clear();
      _selectedPages.addAll(newSelection);
      _parsedRanges = _parseRangesToList(input);
    });
  }

  List<List<int>> _parseRangesToList(String input) {
    final ranges = <List<int>>[];
    final parts = input.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final rangeParts = trimmed.split('-');
        if (rangeParts.length == 2) {
          final start = int.tryParse(rangeParts[0].trim());
          final end = int.tryParse(rangeParts[1].trim());
          if (start != null && end != null) {
            ranges.add([start, end]);
          }
        }
      } else {
        final page = int.tryParse(trimmed);
        if (page != null) {
          ranges.add([page, page]);
        }
      }
    }

    return ranges;
  }

  void _selectAllPages() {
    setState(() {
      _selectedPages.clear();
      _selectedPages.addAll(List.generate(_totalPages, (index) => index + 1));
      _updateRangeText();
    });
  }

  void _updateRangeText() {
    if (_selectedPages.isEmpty) {
      _rangeController.clear();
      return;
    }

    final sortedPages = _selectedPages.toList()..sort();
    _rangeController.text = _formatPageRanges(sortedPages);
  }

  String _formatPageRanges(List<int> pages) {
    if (pages.isEmpty) return '';

    final ranges = <String>[];
    int? rangeStart;
    int? previous;

    for (final page in pages) {
      if (rangeStart == null) {
        rangeStart = page;
        previous = page;
      } else if (page == previous! + 1) {
        previous = page;
      } else {
        if (rangeStart == previous) {
          ranges.add(rangeStart.toString());
        } else {
          ranges.add('$rangeStart-$previous');
        }
        rangeStart = page;
        previous = page;
      }
    }

    // Add the last range
    if (rangeStart != null) {
      if (rangeStart == previous) {
        ranges.add(rangeStart.toString());
      } else {
        ranges.add('$rangeStart-$previous');
      }
    }

    return ranges.join(', ');
  }

  Future<void> _extractText() async {
    if (_selectedPages.isEmpty) return;

    try {
      final text = await DocumentExtractionService.extractFromPdf(
        widget.file,
        pages: _selectedPages.toList(),
      );

      if (!mounted) return;

      // Cache the extracted document
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final cacheService = DocumentCacheService(dbProvider);
      
      final sortedPages = _selectedPages.toList()..sort();
      await cacheService.cacheDocument(
        fileName: widget.file.path.split('/').last,
        filePath: widget.file.path,
        extractedText: text,
        selectedScope: 'pages',
        scopeDetails: {
          'pages': sortedPages,
          'rangeText': _formatPageRanges(sortedPages),
        },
        totalPages: _totalPages,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TextPreviewScreen(
            text: text,
            source: 'PDF (${_selectedPages.length} pages: ${_formatPageRanges(_selectedPages.toList()..sort())})',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to extract text: $e')),
      );
    }
  }
}