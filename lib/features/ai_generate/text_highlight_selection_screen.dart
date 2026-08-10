import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/services/document_extraction_service.dart';
import 'text_preview_screen.dart';

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
  // PdfViewerController? _pdfViewerController;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final text = await DocumentExtractionService.extractFromFile(widget.file);
      
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
      appBar: AppBar(
        title: const Text('Select Text'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
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
          child: FutureBuilder<Uint8List>(
            future: widget.file.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              // TODO: Replace with compatible PDF viewer
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('PDF viewer temporarily disabled'),
                  ],
                ),
              );
              /*
              return SfPdfViewer.memory(
                snapshot.data!,
                controller: _pdfViewerController,
              );
              */
            },
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
        // Text editor
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: 'Select or edit the text to use...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (value) {
                setState(() {
                  _selectedText = value;
                });
              },
            ),
          ),
        ),
        // Selection info
        if (_selectedText.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedText.length} characters selected',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This text will be used to generate questions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _proceedWithSelection() {
    if (_selectedText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select some text first')),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => TextPreviewScreen(
          text: _selectedText,
          source: 'Selected text (${_selectedText.length} characters)',
        ),
      ),
    );
  }
}