import 'dart:async' show unawaited;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:pdf_manipulator/io.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/page_selection_provider.dart';
import '../../core/services/cached_document_service.dart';
import '../../core/services/dialog_service.dart';
import '../../core/services/document_cache_service.dart';
import '../../core/services/document_extraction_service.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/stepper_header.dart';
import 'analysis_preview_screen.dart';

/// PPTX slide selector that converts the presentation to a temporary PDF,
/// then reuses the existing PDF thumbnail pipeline so users see real slide
/// previews while still extracting from the original PPTX file.
class PptxPageRangeSelectorScreen extends StatefulWidget {
  final File pptxFile;

  const PptxPageRangeSelectorScreen({
    super.key,
    required this.pptxFile,
  });

  @override
  State<PptxPageRangeSelectorScreen> createState() => _PptxPageRangeSelectorScreenState();
}

class _PptxPageRangeSelectorScreenState extends State<PptxPageRangeSelectorScreen> {
  bool _isConverting = true;
  bool _isLoading = true;
  String? _errorMessage;
  int _totalSlides = 0;
  final TextEditingController _rangeController = TextEditingController();
  final Set<int> _selectedSlides = {};
  final Map<String, Future<Uint8List?>> _thumbnailFutures = {};
  PdfController? _pdfController;
  PdfDocument? _pdfDocument;
  late final PageSelectionProvider _pageSelection;
  File? _tempPdfFile;

  @override
  void initState() {
    super.initState();
    _pageSelection = context.read<PageSelectionProvider>();
    _convertAndLoad();
  }

  @override
  void dispose() {
    _pageSelection.clear();
    _pageSelection.applyRangeInput(_rangeController.text);
    _rangeController.dispose();
    _pdfController?.dispose();
    try {
      _pdfDocument?.close();
    } catch (_) {}
    if (_tempPdfFile != null) {
      unawaited(_tempPdfFile!.delete().then(
        (_) => null,
        onError: (_) => null,
      ));
    }
    super.dispose();
  }

  Future<void> _convertAndLoad() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final baseName = p.basenameWithoutExtension(widget.pptxFile.path);
      _tempPdfFile = File(p.join(tempDir.path, '${baseName}_preview.pdf'));

      final pdf = Pdf();
      final sink = await FileSink.create(_tempPdfFile!);
      try {
        final task = pdf.convertToPdf(
          FileSource(widget.pptxFile),
          sink,
          format: PdfDocumentFormat.pptx,
        );
        await task;
      } finally {
        await sink.close();
        await pdf.dispose();
      }

      await _loadPdfInfo();
    } catch (e) {
      setState(() {
        _isConverting = false;
        _isLoading = false;
        _errorMessage = 'Failed to prepare slide previews: $e';
      });
    }
  }

  Future<Uint8List?> _loadThumbnail(int slideNumber, double width) async {
    if (_pdfDocument == null) return null;

    try {
      final page = await _pdfDocument!.getPage(slideNumber);
      try {
        final aspect = page.height / page.width;
        final image = await page.render(
          width: width,
          height: width * aspect,
          format: PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        if (image == null) throw Exception('Slide render returned null');
        return image.bytes;
      } finally {
        await page.close();
      }
    } catch (e) {
      debugPrint('PPTX thumbnail render error for slide $slideNumber: $e');
      return null;
    }
  }

  Future<void> _loadPdfInfo() async {
    final bytes = await _tempPdfFile!.readAsBytes();
    _pdfController = PdfController(document: PdfDocument.openData(bytes));
    _pdfDocument = await _pdfController!.document;

    final previousTotal = _pageSelection.totalPages;
    _pageSelection.setTotalPages(_pdfDocument!.pagesCount);
    if (previousTotal == _pdfDocument!.pagesCount) {
      _selectedSlides.addAll(_pageSelection.selectedPages);
      _rangeController.text = _pageSelection.rangeInput;
      _parsedRanges = _parseRangesToList(_pageSelection.rangeInput);
    }

    setState(() {
      _totalSlides = _pdfDocument!.pagesCount;
      _isConverting = false;
      _isLoading = false;
    });
  }

  List<List<int>> _parsedRanges = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Select Slides',
        actions: [
          if (_selectedSlides.isNotEmpty)
            TextButton.icon(
              onPressed: _selectedSlides.isEmpty ? null : _extractText,
              icon: const Icon(Icons.check),
              label: Text('Extract (${_selectedSlides.length})'),
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
            child: _isConverting
                ? _buildConvertingState()
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildSlideSelector(),
          ),
        ],
      ),
    );
  }

  Widget _buildConvertingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Preparing slide previews...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Converting presentation for visual selection',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
            'Failed to load presentation',
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

  Widget _buildSlideSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDocumentInfo(),
          const SizedBox(height: 24),
          _buildRangeInput(),
          const SizedBox(height: 24),
          _buildSlideGrid(),
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
            Icons.slideshow,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pptxFile.path.split('/').last,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$_totalSlides slides total',
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
          'Enter Slide Ranges',
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
                _selectedSlides.clear();
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
                onPressed: _selectAllSlides,
                icon: const Icon(Icons.select_all),
                label: const Text('Select All'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlideGrid() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Slides',
              style: textTheme.titleMedium,
            ),
            if (_selectedSlides.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedSlides.clear();
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
            maxCrossAxisExtent: 220,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _totalSlides,
          itemBuilder: (context, index) {
            final slideNumber = index + 1;
            final isSelected = _selectedSlides.contains(slideNumber);

            final dpr = MediaQuery.devicePixelRatioOf(context);
            const logicalWidth = 220.0;
            final renderWidth = logicalWidth * dpr;
            final cacheKey = '${slideNumber}_${renderWidth.toInt()}';

            _thumbnailFutures[cacheKey] ??= _loadThumbnail(slideNumber, renderWidth);
            final thumbnailFuture = _thumbnailFutures[cacheKey]!;

            return Semantics(
              button: true,
              selected: isSelected,
              label: 'Slide $slideNumber, ${isSelected ? 'selected' : 'not selected'}',
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSlides.remove(slideNumber);
                    } else {
                      _selectedSlides.add(slideNumber);
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
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FutureBuilder<Uint8List?>(
                          future: thumbnailFuture,
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
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.slideshow_outlined,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Slide $slideNumber',
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                              gaplessPlayback: true,
                            );
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'Slide $slideNumber',
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
                              radius: 14,
                              backgroundColor: colorScheme.primary,
                              child: Icon(
                                Icons.check,
                                size: 16,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                      ],
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
    if (_selectedSlides.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedSlides = _selectedSlides.toList()..sort();
    final rangeText = _formatSlideRanges(sortedSlides);

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
                '${_selectedSlides.length} slides selected',
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
              if (i >= 1 && i <= _totalSlides) {
                newSelection.add(i);
              }
            }
          }
        }
      } else {
        final slide = int.tryParse(trimmed);
        if (slide != null && slide >= 1 && slide <= _totalSlides) {
          newSelection.add(slide);
        }
      }
    }

    setState(() {
      _selectedSlides.clear();
      _selectedSlides.addAll(newSelection);
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
        final slide = int.tryParse(trimmed);
        if (slide != null) {
          ranges.add([slide, slide]);
        }
      }
    }

    return ranges;
  }

  void _selectAllSlides() {
    setState(() {
      _selectedSlides.clear();
      _selectedSlides.addAll(List.generate(_totalSlides, (index) => index + 1));
      _updateRangeText();
    });
  }

  void _updateRangeText() {
    if (_selectedSlides.isEmpty) {
      _rangeController.clear();
      return;
    }

    final sortedSlides = _selectedSlides.toList()..sort();
    _rangeController.text = _formatSlideRanges(sortedSlides);
  }

  String _formatSlideRanges(List<int> slides) {
    if (slides.isEmpty) return '';

    final ranges = <String>[];
    int? rangeStart;
    int? previous;

    for (final slide in slides) {
      if (rangeStart == null) {
        rangeStart = slide;
        previous = slide;
      } else if (slide == previous! + 1) {
        previous = slide;
      } else {
        if (rangeStart == previous) {
          ranges.add(rangeStart.toString());
        } else {
          ranges.add('$rangeStart-$previous');
        }
        rangeStart = slide;
        previous = slide;
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

  Future<void> _extractText() async {
    if (_selectedSlides.isEmpty) return;

    try {
      final text = await DocumentExtractionService.extractFromPptx(
        widget.pptxFile,
        pages: _selectedSlides.toList(),
      );

      if (!mounted) return;

      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final cacheService = CachedDocumentService(DocumentCacheService(dbProvider));

      final sortedSlides = _selectedSlides.toList()..sort();
      final rangeText = _formatSlideRanges(sortedSlides);

      await cacheService.cacheDocument(
        fileName: widget.pptxFile.path.split('/').last,
        filePath: widget.pptxFile.path,
        rawText: text,
        selectedScope: 'pages',
        totalPages: _totalSlides,
        source: 'PPTX ($rangeText)',
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AnalysisPreviewScreen(
            text: text,
            source: 'PPTX selected slides',
            scopeType: 'pages',
            scopeDetails: {
              'pages': sortedSlides,
              'rangeText': rangeText,
              'characterCount': text.length,
            },
            totalPages: _totalSlides,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      DialogService.showError(context, 'Failed to extract slides: $e');
    }
  }
}
