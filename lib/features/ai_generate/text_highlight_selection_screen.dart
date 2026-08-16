import 'dart:io';
import 'package:flutter/material.dart';
import '../../shared/widgets/app_bar.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import '../../core/services/document_extraction_service.dart';
import '../../core/providers/highlighted_selection_provider.dart';
import '../../shared/widgets/selectable_document_viewer.dart';
import '../../shared/widgets/selected_text_summary_sheet.dart';
import '../../shared/widgets/stepper_header.dart';
import 'analysis_preview_screen.dart';
import '../../core/services/dialog_service.dart';

class TextHighlightSelectionScreen extends StatefulWidget {
  final File file;
  final String fileType;

  const TextHighlightSelectionScreen({
    super.key,
    required this.file,
    required this.fileType,
  });

  @override
  State<TextHighlightSelectionScreen> createState() => _TextHighlightSelectionScreenState();
}

class _TextHighlightSelectionScreenState extends State<TextHighlightSelectionScreen> {
  bool _isLoading = true;
  bool _isTextMode = false;
  String? _errorMessage;
  String _selectedText = '';
  final TextEditingController _textController = TextEditingController();
  PdfController? _pdfController;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _textController.dispose();
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final text = await DocumentExtractionService.extractFromFile(widget.file);
      
      // Initialize PDF controller if it's a PDF file
      if (widget.fileType == 'pdf') {
        final bytes = await widget.file.readAsBytes();
        _pdfController = PdfController(
          document: PdfDocument.openData(bytes),
        );
      }
      
      setState(() {
        _textController.text = text;
        _isLoading = false;
      });
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
      appBar: CustomAppBar(
        title: 'Select Text',
        actions: [
          if (widget.fileType == 'pdf')
            IconButton(
              icon: Icon(_isTextMode ? Icons.picture_as_pdf : Icons.text_snippet),
              onPressed: () {
                setState(() {
                  _isTextMode = !_isTextMode;
                });
              },
              tooltip: _isTextMode ? 'View PDF' : 'View Text',
            ),
          if (_selectedText.isNotEmpty)
            TextButton.icon(
              onPressed: _proceedWithSelection,
              icon: const Icon(Icons.check),
              label: const Text('Use Selected'),
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
                    : _buildContent(),
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

  Widget _buildContent() {
    if (widget.fileType == 'pdf' && !_isTextMode) {
      return _buildPdfViewer();
    } else {
      return _buildTextEditor();
    }
  }

  Widget _buildPdfViewer() {
    return Column(
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Switch to text mode to select specific content',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        // PDF Viewer
        Expanded(
          child: _pdfController != null
              ? PdfView(
                  controller: _pdfController!,
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
        ),
      ],
    );
  }

  Widget _buildTextEditor() {
    return Column(
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select the text you want to use for question generation',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        // Selectable viewer
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SelectableDocumentViewer(
              text: _textController.text,
              onSelectionChanged: (value) {
                setState(() => _selectedText = value);
                context.read<HighlightedSelectionProvider>().setSelection(value);
              },
            ),
          ),
        ),
        // Selection summary
        if (_selectedText.isNotEmpty)
          SelectedTextSummarySheet(
            selectedText: _selectedText,
            onAnalyze: _proceedWithSelection,
          ),
      ],
    );
  }

  void _proceedWithSelection() {
    if (_selectedText.trim().isEmpty) {
      DialogService.showWarning(context, 'Please select some text first');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnalysisPreviewScreen(
          text: _selectedText,
          source: 'Selected text',
          scopeType: 'highlight',
          scopeDetails: {'characterCount': _selectedText.length},
          totalPages: 0,
        ),
      ),
    );
  }
}