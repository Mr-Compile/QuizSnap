import 'package:flutter/material.dart';
import '../../core/services/document_extraction_service.dart';
import 'ai_generation_config_screen.dart';

class TextPreviewScreen extends StatefulWidget {
  final String text;
  final String source;

  const TextPreviewScreen({
    super.key,
    required this.text,
    required this.source,
  });

  @override
  State<TextPreviewScreen> createState() => _TextPreviewScreenState();
}

class _TextPreviewScreenState extends State<TextPreviewScreen> {
  late TextEditingController _textController;
  late Map<String, int> _statistics;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.text);
    _statistics = DocumentExtractionService.getTextStatistics(widget.text);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Content'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Enable editing mode
              // TODO: Implement edit mode toggle
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Source info and statistics
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Source: ${widget.source}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildStatChip('Words', _statistics['words'] ?? 0),
                    _buildStatChip('Sentences', _statistics['sentences'] ?? 0),
                    _buildStatChip('Paragraphs', _statistics['paragraphs'] ?? 0),
                    _buildStatChip('Characters', _statistics['characters'] ?? 0),
                  ],
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
                  hintText: 'Edit the extracted text if needed...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ),
          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _textController.text.trim().isEmpty
                          ? null
                          : _proceedToGeneration,
                      child: const Text('Generate Questions'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToGeneration() {
    final editedText = _textController.text.trim();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiGenerationConfigScreen(
          sourceText: editedText,
          source: widget.source,
        ),
      ),
    );
  }
}