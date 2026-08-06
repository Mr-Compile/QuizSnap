import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/prompt_template.dart';
import '../../core/repositories/prompt_template_repository.dart';

class PromptBuilderScreen extends StatefulWidget {
  const PromptBuilderScreen({super.key});

  @override
  State<PromptBuilderScreen> createState() => _PromptBuilderScreenState();
}

class _PromptBuilderScreenState extends State<PromptBuilderScreen> {
  final PromptTemplateRepository _templateRepository = PromptTemplateRepository();
  
  PromptTemplate? _selectedTemplate;
  PromptType _selectedType = PromptType.multipleChoice;
  Difficulty _selectedDifficulty = Difficulty.medium;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _templateController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _countController = TextEditingController(text: '5');
  
  bool _isCustomTemplate = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _templateRepository.initialize();
    _selectedTemplate = _templateRepository.builtInTemplates.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _templateController.dispose();
    _contentController.dispose();
    _countController.dispose();
    super.dispose();
  }

  String _buildPreviewPrompt() {
    if (_isCustomTemplate) {
      return _templateController.text;
    } else if (_selectedTemplate != null) {
      return _templateRepository.buildPrompt(_selectedTemplate!, {
        'content': _contentController.text,
        'count': _countController.text,
        'difficulty': _selectedDifficulty.displayName.toLowerCase(),
        'number': _countController.text,
      });
    }
    return '';
  }

  void _toggleTemplateMode(bool isCustom) {
    setState(() {
      _isCustomTemplate = isCustom;
      if (!isCustom) {
        _selectedTemplate = _templateRepository.builtInTemplates.first;
      }
    });
  }

  void _saveTemplate() async {
    if (_isCustomTemplate) {
      if (_nameController.text.isEmpty || _templateController.text.isEmpty) {
        _showErrorDialog('Please fill in the template name and content.');
        return;
      }

      final template = PromptTemplate(
        id: '',
        name: _nameController.text,
        description: _descriptionController.text,
        template: _templateController.text,
        type: _selectedType,
        difficulty: _selectedDifficulty,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _templateRepository.addCustomTemplate(template);
      _showSuccessDialog('Template saved successfully!');
    } else {
      _showSuccessDialog('Built-in template selected.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(PromptType type) {
    switch (type) {
      case PromptType.multipleChoice:
        return AppTheme.bambooGreen600;
      case PromptType.identification:
        return AppTheme.blue600;
      case PromptType.enumeration:
        return AppTheme.purple600;
      case PromptType.examSimulation:
        return AppTheme.amber600;
      case PromptType.explanation:
        return AppTheme.red600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Prompt Builder',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? AppTheme.slate800 : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () {
              setState(() {
                _showPreview = !_showPreview;
              });
            },
            tooltip: 'Toggle Preview',
          ),
        ],
      ),
      backgroundColor: isDark ? AppTheme.slate900 : AppTheme.slate50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template Mode Toggle
            _buildTemplateModeToggle(isDark),
            const SizedBox(height: 24),

            if (_isCustomTemplate) ...[
              // Custom Template Form
              _buildCustomTemplateForm(isDark),
            ] else ...[
              // Built-in Template Selection
              _buildTemplateSelector(isDark),
              const SizedBox(height: 24),
            ],

            // Variables Section
            _buildVariablesSection(isDark),
            const SizedBox(height: 24),

            // Preview Section
            if (_showPreview) ...[
              _buildPreviewSection(isDark),
              const SizedBox(height: 24),
            ],

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveTemplate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.bambooGreen600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isCustomTemplate ? 'Save Template' : 'Use Template',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateModeToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate800 : AppTheme.slate200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleTemplateMode(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isCustomTemplate
                      ? AppTheme.bambooGreen600
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Built-in Templates',
                  style: GoogleFonts.poppins(
                    color: !_isCustomTemplate ? Colors.white : AppTheme.slate600,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleTemplateMode(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isCustomTemplate
                      ? AppTheme.bambooGreen600
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Custom Template',
                  style: GoogleFonts.poppins(
                    color: _isCustomTemplate ? Colors.white : AppTheme.slate600,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Template',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.slate800,
          ),
        ),
        const SizedBox(height: 12),
        ..._templateRepository.builtInTemplates.map((template) {
          return _TemplateTile(
            template: template,
            isSelected: _selectedTemplate?.id == template.id,
            onTap: () {
              setState(() {
                _selectedTemplate = template;
                _selectedType = template.type;
                _selectedDifficulty = template.difficulty;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildCustomTemplateForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Template Name',
          hint: 'e.g., Biology Questions',
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'What does this template do?',
          isDark: isDark,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Question Type',
          value: _selectedType,
          items: PromptType.values,
          isDark: isDark,
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Difficulty',
          value: _selectedDifficulty,
          items: Difficulty.values,
          isDark: isDark,
          onChanged: (value) {
            setState(() {
              _selectedDifficulty = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _templateController,
          label: 'Template Content',
          hint: 'Use {content}, {count}, {difficulty} as variables',
          isDark: isDark,
          maxLines: 8,
        ),
      ],
    );
  }

  Widget _buildVariablesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Variables',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.slate800,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _contentController,
          label: 'Study Material',
          hint: 'Paste your notes or study material here...',
          isDark: isDark,
          maxLines: 6,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _countController,
          label: 'Number of Questions',
          hint: 'e.g., 5',
          isDark: isDark,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildPreviewSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.slate800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.slate800 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.slate700 : AppTheme.slate200,
            ),
          ),
          child: Text(
            _buildPreviewPrompt(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? AppTheme.slate300 : AppTheme.slate700,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppTheme.slate300 : AppTheme.slate600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDark ? Colors.white : AppTheme.slate800,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.slate400,
            ),
            filled: true,
            fillColor: isDark ? AppTheme.slate800 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppTheme.slate700 : AppTheme.slate200,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppTheme.slate700 : AppTheme.slate200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.bambooGreen600,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required bool isDark,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppTheme.slate300 : AppTheme.slate600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items.map((item) {
            String displayName;
            if (item is PromptType) {
              displayName = item.displayName;
            } else if (item is Difficulty) {
              displayName = item.displayName;
            } else {
              displayName = item.toString();
            }
            return DropdownMenuItem(
              value: item,
              child: Text(
                displayName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppTheme.slate800,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppTheme.slate800 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppTheme.slate700 : AppTheme.slate200,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppTheme.slate700 : AppTheme.slate200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.bambooGreen600,
                width: 2,
              ),
            ),
          ),
          dropdownColor: isDark ? AppTheme.slate800 : Colors.white,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDark ? Colors.white : AppTheme.slate800,
          ),
        ),
      ],
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final PromptTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateTile({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.bambooGreen600.withValues(alpha: 0.1)
              : (isDark ? AppTheme.slate800 : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.bambooGreen600
                : (isDark ? AppTheme.slate700 : AppTheme.slate200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getTypeColor(template.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  template.type.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.slate800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.bambooGreen600,
              ),
          ],
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.slate800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.bambooGreen600,
              ),
          ],
        ),
      ),
    );
  }
}