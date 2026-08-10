import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/services/document_extraction_service.dart';
import 'text_preview_screen.dart';

class PdfPreviewScreen extends StatefulWidget {
  final File file;

  const PdfPreviewScreen({
    super.key,
    required this.file,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _selectedPages = {};
  int _totalPages = 0;
  // PdfViewerController? _pdfViewerController;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final bytes = await widget.file.readAsBytes();
      
      // TODO: Load PDF to get page count with compatible library
      // final doc = PdfDocument(inputBytes: bytes);
      setState(() {
        _totalPages = 1; // Placeholder
        _isLoading = false;
        _errorMessage = 'PDF preview temporarily disabled - need compatible PDF library';
      });
      
      // _pdfViewerController = PdfViewerController();
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
        title: const Text('Preview PDF'),
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
              : _buildPageGrid(),
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

  Widget _buildPageGrid() {
    return Column(
      children: [
        // Selection controls
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Checkbox(
                value: _selectedPages.length == _totalPages,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedPages.addAll(
                        List.generate(_totalPages, (index) => index + 1),
                      );
                    } else {
                      _selectedPages.clear();
                    }
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedPages.isEmpty
                      ? 'Select pages to extract'
                      : '${_selectedPages.length} of $_totalPages pages selected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
        ),
        // PDF Viewer
        Expanded(
          child: _buildErrorState(),
        ),
      ],
    );
  }

  Future<void> _extractText() async {
    if (_selectedPages.isEmpty) return;

    try {
      final text = await DocumentExtractionService.extractFromPdf(
        widget.file,
        pages: _selectedPages.toList(),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TextPreviewScreen(
            text: text,
            source: 'PDF (${_selectedPages.length} pages)',
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