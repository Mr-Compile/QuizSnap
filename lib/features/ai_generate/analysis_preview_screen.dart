import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/prompt_template.dart';
import '../../core/services/document_extraction_service.dart';
import '../../core/services/text_normalization_service.dart';
import '../../core/providers/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/formatted_study_text.dart';
import 'ai_generation_config_screen.dart';
import 'text_preview_screen.dart';

/// Mandatory final confirmation before sending the selected scope to AI.
class AnalysisPreviewScreen extends StatefulWidget {
  final String text;
  final String source;
  final String scopeType;
  final Map<String, dynamic> scopeDetails;
  final int totalPages;

  const AnalysisPreviewScreen({
    super.key,
    required this.text,
    required this.source,
    required this.scopeType,
    this.scopeDetails = const {},
    this.totalPages = 0,
  });

  @override
  State<AnalysisPreviewScreen> createState() => _AnalysisPreviewScreenState();
}

class _AnalysisPreviewScreenState extends State<AnalysisPreviewScreen> {
  PromptType _selectedType = PromptType.multipleChoice;
  Difficulty _selectedDifficulty = Difficulty.medium;

  @override
  Widget build(BuildContext context) {
    final stats = DocumentExtractionService.getTextStatistics(widget.text);
    final charCount = stats['characters'] ?? 0;
    final estimatedTokens = (charCount / 4).round();
    final isLarge = estimatedTokens > 6000;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Preview for AI'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(charCount, estimatedTokens),
                  if (isLarge) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    _buildSizeWarning(),
                  ],
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildScopeSummary(),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildTypeSelector(),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildDifficultySelector(),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    'Selected content',
                    style: AppTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  FormattedStudyText(
                    text: TextNormalizationService.reconstruct(widget.text),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(int charCount, int estimatedTokens) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Source', style: AppTheme.labelLarge),
            Text(widget.source, style: AppTheme.bodyMedium),
            const Divider(),
            _buildInfoRow('Scope', _scopeDisplayName()),
            _buildInfoRow('Characters', charCount.toString()),
            _buildInfoRow('Est. tokens', '~$estimatedTokens'),
            _buildInfoRow('Pages', widget.totalPages > 0 ? '${widget.totalPages}' : 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium),
          Text(value, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSizeWarning() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              'This document is very large. AI generation may be slow or truncated.',
              style: AppTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeSummary() {
    final summary = _scopeSummaryText();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selection', style: AppTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingXs),
            Text(summary, style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  String _scopeDisplayName() {
    switch (widget.scopeType) {
      case 'all':
        return 'Entire Document';
      case 'pages':
        return 'Specific Pages';
      case 'headings':
        return 'By Chapter/Heading';
      case 'highlight':
        return 'Highlighted Text';
      default:
        return 'Custom';
    }
  }

  String _scopeSummaryText() {
    final details = widget.scopeDetails;
    switch (widget.scopeType) {
      case 'pages':
        final ranges = details['rangeText'] as String? ?? '';
        return 'Pages: $ranges';
      case 'headings':
        final headings = (details['headings'] as List?)?.cast<String>() ?? [];
        if (headings.isEmpty) return 'All detected headings';
        if (headings.length == 1) return headings.first;
        return '${headings.length} sections selected';
      case 'highlight':
        final chars = details['characterCount'] as int? ?? widget.text.length;
        return '$chars highlighted characters';
      default:
        return 'Full document (${widget.totalPages} pages)';
    }
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question Type', style: AppTheme.titleLarge),
        const SizedBox(height: AppTheme.spacingSm),
        DropdownButtonFormField<PromptType>(
          initialValue: _selectedType,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: PromptType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedType = value);
          },
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Difficulty', style: AppTheme.titleLarge),
        const SizedBox(height: AppTheme.spacingSm),
        DropdownButtonFormField<Difficulty>(
          initialValue: _selectedDifficulty,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: Difficulty.values.map((difficulty) {
            return DropdownMenuItem(
              value: difficulty,
              child: Text(difficulty.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedDifficulty = value);
          },
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _editText,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Text'),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Generate Questions',
                icon: Icons.auto_awesome,
                onPressed: _generate,
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editText() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TextPreviewScreen(
          text: widget.text,
          source: widget.source,
        ),
      ),
    );
  }

  void _generate() {
    if (widget.text.trim().isEmpty) {
      context.read<NotificationService>().showErrorTop('No content selected for AI generation');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiGenerationConfigScreen(
          sourceText: widget.text,
          source: '${widget.source} • ${_scopeDisplayName()}',
        ),
      ),
    );
  }
}
