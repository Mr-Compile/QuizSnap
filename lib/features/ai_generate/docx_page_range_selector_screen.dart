import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/document_extraction_service.dart';
import '../../core/services/document_cache_service.dart';
import '../../core/services/cached_document_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/dialog_service.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/stepper_header.dart';
import 'analysis_preview_screen.dart';

class DocxPageRangeSelectorScreen extends StatefulWidget {
  final File file;

  const DocxPageRangeSelectorScreen({
    super.key,
    required this.file,
  });

  @override
  State<DocxPageRangeSelectorScreen> createState() => _DocxPageRangeSelectorScreenState();
}

class _DocxPageRangeSelectorScreenState extends State<DocxPageRangeSelectorScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<String> _pageTexts = const [];
  final Set<int> _selectedPages = {};

  @override
  void initState() {
    super.initState();
    _loadDocxPages();
  }

  Future<void> _loadDocxPages() async {
    try {
      final pages = await DocumentExtractionService.extractDocxPages(widget.file);
      if (!mounted) return;
      setState(() {
        _pageTexts = pages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load DOCX pages: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Select DOCX Pages',
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
            'Failed to load DOCX',
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
          _buildDocumentInfo(),
          const SizedBox(height: 24),
          _buildPageGrid(),
          const SizedBox(height: 24),
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
            Icons.description,
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
                  '${_pageTexts.length} pages',
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _selectAllPages,
                  child: const Text('Select All'),
                ),
                if (_selectedPages.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedPages.clear();
                      });
                    },
                    child: const Text('Clear'),
                  ),
              ],
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
          itemCount: _pageTexts.length,
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
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
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
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _previewText(index),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  height: 1.4,
                                ),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                          padding: const EdgeInsets.symmetric(vertical: 6),
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

  String _previewText(int index) {
    final text = _pageTexts[index];
    if (text.length <= 400) return text;
    return '${text.substring(0, 400)}...';
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

    if (rangeStart != null) {
      if (rangeStart == previous) {
        ranges.add(rangeStart.toString());
      } else {
        ranges.add('$rangeStart-$previous');
      }
    }

    return ranges.join(', ');
  }

  void _selectAllPages() {
    setState(() {
      _selectedPages.addAll(List.generate(_pageTexts.length, (index) => index + 1));
    });
  }

  Future<void> _extractText() async {
    if (_selectedPages.isEmpty || _pageTexts.isEmpty) return;

    try {
      final sortedPages = _selectedPages.toList()..sort();
      final buffer = StringBuffer();
      for (final page in sortedPages) {
        if (buffer.isNotEmpty) buffer.write('\n\n');
        buffer.write(_pageTexts[page - 1]);
      }
      final text = buffer.toString().trim();

      if (text.isEmpty) {
        DialogService.showError(context, 'Selected pages contain no usable text');
        return;
      }

      if (!mounted) return;

      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final cacheService = CachedDocumentService(DocumentCacheService(dbProvider));
      final rangeText = _formatPageRanges(sortedPages);

      await cacheService.cacheDocument(
        fileName: widget.file.path.split('/').last,
        filePath: widget.file.path,
        rawText: text,
        selectedScope: 'pages',
        totalPages: _pageTexts.length,
        source: 'DOCX ($rangeText)',
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AnalysisPreviewScreen(
            text: text,
            source: 'DOCX selected pages',
            scopeType: 'pages',
            scopeDetails: {
              'pages': sortedPages,
              'rangeText': rangeText,
              'characterCount': text.length,
            },
            totalPages: _pageTexts.length,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      DialogService.showError(context, 'Failed to extract text: $e');
    }
  }
}
