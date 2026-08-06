import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../core/models/export.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/export_service.dart';
import '../../core/repositories/deck_repository.dart';
import '../../core/repositories/flashcard_repository.dart';
import '../../core/repositories/folder_repository.dart';
import '../../core/repositories/tag_repository.dart';
import 'pdf_preview_screen.dart';
import 'export_success_screen.dart';

class ExportOptionsScreen extends StatefulWidget {
  final ExportType initialType;
  final ExportFormat initialFormat;
  final int? deckId;

  const ExportOptionsScreen({
    super.key,
    required this.initialType,
    required this.initialFormat,
    this.deckId,
  });

  @override
  State<ExportOptionsScreen> createState() => _ExportOptionsScreenState();
}

class _ExportOptionsScreenState extends State<ExportOptionsScreen> {
  late ExportFormat _selectedFormat;
  late ExportType _selectedType;
  bool _includeAnswers = true;
  bool _includeExplanations = false;
  bool _includeTags = false;
  bool _shuffleQuestions = false;
  int? _questionLimit;
  String _customTitle = '';
  String _customDescription = '';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat;
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Export Options',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFormatSelector(),
          const SizedBox(height: 24),
          _buildTypeSelector(),
          const SizedBox(height: 24),
          _buildOptionsSection(),
          const SizedBox(height: 24),
          _buildCustomFields(),
          const SizedBox(height: 24),
          _buildExportButton(),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Format',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ExportFormat.values.map((format) {
              return _FormatChip(
                format: format,
                isSelected: _selectedFormat == format,
                onTap: () => setState(() => _selectedFormat = format),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ExportType.values.map((type) {
              return _TypeChip(
                type: type,
                isSelected: _selectedType == type,
                onTap: () => setState(() => _selectedType = type),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Include Answers'),
            subtitle: const Text('Show answers in the export'),
            value: _includeAnswers,
            onChanged: (value) => setState(() => _includeAnswers = value),
          ),
          SwitchListTile(
            title: const Text('Include Explanations'),
            subtitle: const Text('Include detailed explanations'),
            value: _includeExplanations,
            onChanged: (value) => setState(() => _includeExplanations = value),
          ),
          SwitchListTile(
            title: const Text('Include Tags'),
            subtitle: const Text('Export tags with flashcards'),
            value: _includeTags,
            onChanged: (value) => setState(() => _includeTags = value),
          ),
          SwitchListTile(
            title: const Text('Shuffle Questions'),
            subtitle: const Text('Randomize question order'),
            value: _shuffleQuestions,
            onChanged: (value) => setState(() => _shuffleQuestions = value),
          ),
          const SizedBox(height: 16),
          Text(
            'Question Limit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: (_questionLimit ?? 0).toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            label: _questionLimit == null ? 'All' : '$_questionLimit',
            onChanged: (value) {
              setState(() {
                _questionLimit = value == 0 ? null : value.round();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFields() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Custom Title',
              hintText: 'Leave empty for default title',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _customTitle = value),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Custom Description',
              hintText: 'Leave empty for default description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) => setState(() => _customDescription = value),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return CustomButton(
      text: 'Export',
      icon: Icons.ios_share,
      isLoading: _isExporting,
      fullWidth: true,
      onPressed: _isExporting ? null : _handleExport,
    );
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);

    try {
      final database = context.read<AppDatabase>();
      final exportService = ExportService(
        database,
        DeckRepository(database),
        FlashcardRepository(database),
        FolderRepository(database),
        TagRepository(database),
      );

      final options = ExportOptions(
        format: _selectedFormat,
        type: _selectedType,
        includeAnswers: _includeAnswers,
        includeExplanations: _includeExplanations,
        includeTags: _includeTags,
        shuffleQuestions: _shuffleQuestions,
        questionLimit: _questionLimit,
        customTitle: _customTitle.isEmpty ? null : _customTitle,
        customDescription: _customDescription.isEmpty ? null : _customDescription,
      );

      final result = await exportService.exportData(options, deckId: widget.deckId);

      if (result.status == ExportStatus.completed && result.filePath != null) {
        if (_selectedFormat == ExportFormat.pdf) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PdfPreviewScreen(
                filePath: result.filePath!,
                exportResult: result,
              ),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ExportSuccessScreen(
                exportResult: result,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => ConfirmationDialog(
              title: 'Export Failed',
              content: result.errorMessage ?? 'Unknown error occurred',
              confirmText: 'OK',
              onConfirm: () => Navigator.of(context).pop(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ConfirmationDialog(
            title: 'Export Failed',
            content: e.toString(),
            confirmText: 'OK',
            onConfirm: () => Navigator.of(context).pop(),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

class _FormatChip extends StatelessWidget {
  final ExportFormat format;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatChip({
    required this.format,
    required this.isSelected,
    required this.onTap,
  });

  String get label {
    switch (format) {
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.json:
        return 'JSON';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ExportType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  String get label {
    switch (type) {
      case ExportType.flashcards:
        return 'Flashcards';
      case ExportType.quiz:
        return 'Quiz';
      case ExportType.answerKey:
        return 'Answer Key';
      case ExportType.studyPack:
        return 'Study Pack';
      case ExportType.backup:
        return 'Backup';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}