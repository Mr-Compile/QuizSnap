import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../shared/widgets/app_bar.dart';
import 'package:provider/provider.dart';
import 'package:pdfx/pdfx.dart';
import '../../core/services/document_extraction_service.dart';
import '../../core/services/document_cache_service.dart';
import '../../core/services/cached_document_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/page_selection_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../shared/widgets/stepper_header.dart';
import 'analysis_preview_screen.dart';

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
  final Map<int, Future<Uint8List?>> _thumbnailFutures = {};
  PdfController? _pdfController;
  PdfDocument? _pdfDocument;
  late final PageSelectionProvider _pageSelection;

  @override
  void initState() {
    super.initState();
    _pageSelection = context.read<PageSelectionProvider>();
    _loadPdfInfo();
  }

  @override
  void dispose() {
    // Persist the current selection to the existing provider so it survives
    // navigation away from and back to this screen.
    _pageSelection.clear();
    _pageSelection.applyRangeInput(_rangeController.text);
    _rangeController.dispose();
    _pdfController?.dispose();
    try {
      _pdfDocument?.close();
    } catch (_) {
      // Document may already be closed.
    }
    super.dispose();
  }

  Future<Uint8List?> _loadThumbnail(int pageNumber) async {
    if (_pdfDocument == null) return null;

    try {
      final page = await _pdfDocument!.getPage(pageNumber);
      try {
        final aspect = page.height / page.width;
        const targetWidth = 150.0;
        final image = await page.render(
          width: targetWidth,
          height: targetWidth * aspect,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
        );
        if (image == null) throw Exception('Page render returned null');
        return image.bytes;
      } finally {
        await page.close();
      }
    } catch (e) {
      debugPrint('PDF thumbnail render error for page $pageNumber: $e');
      return null;
    }
  }

  Future<void> _loadPdfInfo() async {
    try {
      final bytes = await widget.file.readAsBytes();

      // Open the PDF once with the existing pdfx implementation and get
      // both the document and the page count from the same source.
      _pdfController = PdfController(
        document: PdfDocument.openData(bytes),
      );
      _pdfDocument = await _pdfController!.document;

      // Preserve the user's previous selection only when the page count
      // matches (same document). Otherwise start fresh to avoid stale data.
      final previousTotal = _pageSelection.totalPages;
      _pageSelection.setTotalPages(_pdfDocument!.pagesCount);
      if (previousTotal == _pdfDocument!.pagesCount) {
        _selectedPages.addAll(_pageSelection.selectedPages);
        _rangeController.text = _pageSelection.rangeInput;
        _parsedRanges = _parseRangesToList(_pageSelection.rangeInput);
      }

      setState(() {
        _totalPages = _pdfDocument!.pagesCount;
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
      appBar: CustomAppBar(
        title: 'Select Page Range',
        actions: [
          if (_selectedPages.isNotEmpty)
            TextButton.icon(
              onPressed: _selectedPages.isEmpty ? null : _extractText,
              icon: const Icon(Icons.check),
              label: Text('Extract (${_selectedPages.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          const StepperHeader(
            currentStep: 1,
            steps: kAiWizardSteps,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildPageSelector(),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Pages',
              style: textTheme.titleMedium,
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
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _totalPages,
          itemBuilder: (context, index) {
            final pageNumber = index + 1;
            final isSelected = _selectedPages.contains(pageNumber);

            _thumbnailFutures[pageNumber] ??= _loadThumbnail(pageNumber);

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
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FutureBuilder<Uint8List?>(
                        future: _thumbnailFutures[pageNumber],
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          if (snapshot.hasError || snapshot.data == null) {
                            return Center(
                              child: Icon(
                                Icons.broken_image,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          }

                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          );
                        },
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Page $pageNumber',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: colorScheme.primary,
                            child: Icon(
                              Icons.check,
                              size: 14,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                    ],
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
      final cacheService = CachedDocumentService(DocumentCacheService(dbProvider));

      final sortedPages = _selectedPages.toList()..sort();
      final rangeText = _formatPageRanges(sortedPages);

      await cacheService.cacheDocument(
        fileName: widget.file.path.split('/').last,
        filePath: widget.file.path,
        rawText: text,
        selectedScope: 'pages',
        totalPages: _totalPages,
        source: 'PDF ($rangeText)',
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AnalysisPreviewScreen(
            text: text,
            source: 'PDF selected pages',
            scopeType: 'pages',
            scopeDetails: {
              'pages': sortedPages,
              'rangeText': rangeText,
              'characterCount': text.length,
            },
            totalPages: _totalPages,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      DialogService.showError(context, 'Failed to extract text: $e');
    }
  }
}