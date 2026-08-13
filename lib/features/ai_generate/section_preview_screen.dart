import 'package:flutter/material.dart';
import '../../core/services/document_extraction_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/formatted_study_text.dart';
import '../../shared/widgets/stepper_header.dart';
import 'ai_generation_config_screen.dart';
import 'text_preview_screen.dart';

/// Mandatory preview of combined selected sections before AI generation.
class SectionPreviewScreen extends StatelessWidget {
  final String text;
  final String source;
  final String scopeType;
  final Map<String, dynamic> scopeDetails;

  const SectionPreviewScreen({
    super.key,
    required this.text,
    required this.source,
    required this.scopeType,
    this.scopeDetails = const {},
  });

  @override
  Widget build(BuildContext context) {
    final stats = DocumentExtractionService.getTextStatistics(text);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Section Preview'),
      body: Column(
        children: [
          const StepperHeader(
            currentStep: 3,
            steps: ['Import', 'Scope', 'Select', 'Preview', 'Generate'],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(context, stats),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    'Selected content',
                    style: AppTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  FormattedStudyText(
                    text: text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Map<String, int> stats) {
    final headings = scopeDetails['headings'] as List? ?? [];
    final pages = scopeDetails['pages'] as List? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Source', style: AppTheme.labelLarge),
            Text(source, style: AppTheme.bodyMedium),
            const Divider(),
            _buildInfoRow('Selected chapters/sections', headings.isEmpty ? 'All' : headings.length.toString()),
            _buildInfoRow('Pages included', pages.isEmpty ? 'All' : pages.length.toString()),
            _buildInfoRow('Characters', '${stats['characters'] ?? 0}'),
            _buildInfoRow('Words', '${stats['words'] ?? 0}'),
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

  Widget _buildBottomActions(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _editText(context),
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
                onPressed: text.trim().isEmpty ? null : () => _generate(context),
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editText(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TextPreviewScreen(
          text: text,
          source: source,
        ),
      ),
    );
  }

  void _generate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiGenerationConfigScreen(
          sourceText: text,
          source: source,
        ),
      ),
    );
  }
}
