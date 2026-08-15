import 'package:flutter/material.dart';
import '../../core/services/document_extraction_service.dart';
import '../../core/services/unified_text_cleaner.dart';
import '../../core/services/dialog_service.dart';
import '../../shared/widgets/formatted_study_text.dart';
import 'ai_generation_config_screen.dart';

class TextPreviewScreen extends StatefulWidget {
  final String text;
  final String source;
  final bool showImportSuccess;

  const TextPreviewScreen({
    super.key,
    required this.text,
    required this.source,
    this.showImportSuccess = false,
  });

  @override
  State<TextPreviewScreen> createState() => _TextPreviewScreenState();
}

class _TextPreviewScreenState extends State<TextPreviewScreen> {
  late TextEditingController _textController;
  late Map<String, int> _statistics;
  late String _originalText;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _originalText = widget.text;
    _textController = TextEditingController(
      text: UnifiedTextCleaner.clean(widget.text, sourceHint: 'txt'),
    );
    _statistics = DocumentExtractionService.getTextStatistics(_textController.text);
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
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.showImportSuccess)
            _buildImportSuccessBanner(context),
          // Source info and statistics
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
          // Text editor / formatted preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isEditing
                    ? TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          hintText: 'Edit the extracted text if needed...',
                          contentPadding: EdgeInsets.all(16),
                          border: InputBorder.none,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlignVertical: TextAlignVertical.top,
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: FormattedStudyText(
                          text: _textController.text,
                          style: Theme.of(context).textTheme.bodyMedium,
                          showActions: true,
                        ),
                      ),
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
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _rearrange,
                          icon: const Icon(Icons.auto_fix_high),
                          label: const Text('Retry Arrangement'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetToOriginal,
                          icon: const Icon(Icons.undo),
                          label: const Text('Reset to Original'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportSuccessBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Text imported successfully',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
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

  void _rearrange() {
    final current = _textController.text.trim();
    final cleaned = UnifiedTextCleaner.clean(current, sourceHint: 'txt');
    setState(() {
      _textController.text = cleaned;
      _statistics = DocumentExtractionService.getTextStatistics(cleaned);
    });
    DialogService.showSuccess(context, 'Text rearranged');
  }

  void _resetToOriginal() {
    setState(() {
      _textController.text = _originalText;
      _statistics = DocumentExtractionService.getTextStatistics(_originalText);
    });
    DialogService.showInfo(context, 'Reset to original text');
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