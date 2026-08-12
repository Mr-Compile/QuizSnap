import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/models/document_section_model.dart';
import '../../core/services/document_extraction_service.dart';
import '../../core/services/heading_detection_service.dart';
import '../../core/services/document_cache_service.dart';
import '../../core/services/cached_document_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/stepper_header.dart';
import 'section_preview_screen.dart';

/// Full-screen hierarchical heading selection for PDFs.
class HeadingTreeSelectionScreen extends StatefulWidget {
  final File file;

  const HeadingTreeSelectionScreen({
    super.key,
    required this.file,
  });

  @override
  State<HeadingTreeSelectionScreen> createState() => _HeadingTreeSelectionScreenState();
}

class _HeadingTreeSelectionScreenState extends State<HeadingTreeSelectionScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<String> _lines = [];
  List<DocumentSection> _sections = [];
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() => _isLoading = true);
    try {
      _totalPages = await DocumentExtractionService.getPageCount(widget.file);
      final text = await DocumentExtractionService.extractFromPdf(widget.file);
      _lines = text.split('\n');
      _sections = HeadingDetectionService.detectSections(text);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to analyze headings: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Select Chapters & Sections'),
      body: Column(
        children: [
          const StepperHeader(
            currentStep: 2,
            steps: ['Import', 'Scope', 'Select', 'Preview', 'Generate'],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildTree(),
          ),
        ],
      ),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : _buildBottomBar(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to analyze headings', style: AppTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_errorMessage ?? 'Unknown error', style: AppTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDocument,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTree() {
    if (_sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.format_list_bulleted, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No headings detected', style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Text('The document does not appear to have chapter or section headings.', style: AppTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      itemCount: _sections.length,
      itemBuilder: (context, index) => _buildSectionTile(_sections[index]),
    );
  }

  Widget _buildSectionTile(DocumentSection section, {int depth = 0}) {
    final selectedCount = _selectedDescendantCount(section);
    final total = _descendantCount(section);
    final isIndeterminate = selectedCount > 0 && selectedCount < total;

    Widget tile = CheckboxListTile(
      value: isIndeterminate ? null : section.isSelected,
      tristate: true,
      onChanged: (value) => _toggleSection(section, value),
      title: Text(
        section.title,
        style: AppTheme.titleMedium.copyWith(
          fontWeight: section.level <= 1 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '${section.estimatedQuestionCount()} estimated questions',
        style: AppTheme.bodySmall,
      ),
    );

    if (section.children.isNotEmpty) {
      return ExpansionTile(
        title: tile,
        initiallyExpanded: true,
        children: section.children.map((child) => _buildSectionTile(child, depth: depth + 1)).toList(),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: depth * AppTheme.spacingMd),
      child: tile,
    );
  }

  Widget _buildBottomBar() {
    final selected = _collectSelected(_sections);
    final estimatedQuestions = selected.fold(0, (sum, s) => sum + s.estimatedQuestionCount());
    final totalChars = DocumentSection.selectedText(_sections, _lines).length;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, -2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${selected.length} sections', style: AppTheme.bodyMedium),
                Text('$estimatedQuestions est. questions', style: AppTheme.bodyMedium),
                Text('$totalChars chars', style: AppTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            CustomButton(
              text: 'Continue',
              icon: Icons.check,
              fullWidth: true,
              onPressed: selected.isEmpty ? null : _continueToPreview,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSection(DocumentSection section, bool? value) {
    HapticFeedback.lightImpact();
    setState(() {
      section.isSelected = value ?? false;
      _propagateToChildren(section, section.isSelected);
    });
  }

  void _propagateToChildren(DocumentSection section, bool selected) {
    for (final child in section.children) {
      child.isSelected = selected;
      _propagateToChildren(child, selected);
    }
  }

  int _selectedDescendantCount(DocumentSection section) {
    int count = section.isSelected ? 1 : 0;
    for (final child in section.children) {
      count += _selectedDescendantCount(child);
    }
    return count;
  }

  int _descendantCount(DocumentSection section) {
    int count = 1;
    for (final child in section.children) {
      count += _descendantCount(child);
    }
    return count;
  }

  List<DocumentSection> _collectSelected(List<DocumentSection> sections) {
    final result = <DocumentSection>[];
    for (final section in sections) {
      if (section.isSelected) {
        result.add(section);
      } else {
        result.addAll(_collectSelected(section.children));
      }
    }
    return result;
  }

  Future<void> _continueToPreview() async {
    final selected = _collectSelected(_sections);
    if (selected.isEmpty) return;

    final text = DocumentSection.selectedText(_sections, _lines);
    final headingNames = selected.map((s) => s.title).toList();

    // Cache the selected scope.
    final db = context.read<DatabaseProvider>();
    await CachedDocumentService(DocumentCacheService(db)).cacheDocument(
      fileName: widget.file.path.split('/').last,
      filePath: widget.file.path,
      rawText: text,
      selectedScope: 'headings',
      totalPages: _totalPages,
      source: 'PDF sections',
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SectionPreviewScreen(
          text: text,
          source: '${widget.file.path.split('/').last} sections',
          scopeType: 'headings',
          scopeDetails: {
            'headings': headingNames,
            'totalPages': _totalPages,
          },
        ),
      ),
    );
  }
}
