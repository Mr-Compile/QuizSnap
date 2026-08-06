import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/prompt_template.dart';
import '../../core/repositories/prompt_template_repository.dart';
import 'prompt_builder_screen.dart';
import 'prompt_preview_screen.dart';

class PromptHistoryScreen extends StatefulWidget {
  const PromptHistoryScreen({super.key});

  @override
  State<PromptHistoryScreen> createState() => _PromptHistoryScreenState();
}

class _PromptHistoryScreenState extends State<PromptHistoryScreen> {
  final PromptTemplateRepository _templateRepository = PromptTemplateRepository();
  
  @override
  void initState() {
    super.initState();
    _templateRepository.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Prompt Templates',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? AppTheme.slate800 : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PromptBuilderScreen(),
                ),
              );
            },
            tooltip: 'Create New Template',
          ),
        ],
      ),
      backgroundColor: isDark ? AppTheme.slate900 : AppTheme.slate50,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Tab Bar
            Container(
              color: isDark ? AppTheme.slate800 : Colors.white,
              child: TabBar(
                labelColor: AppTheme.bambooGreen600,
                unselectedLabelColor: isDark ? AppTheme.slate400 : AppTheme.slate600,
                indicatorColor: AppTheme.bambooGreen600,
                tabs: [
                  Tab(
                    child: Text(
                      'Built-in',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Custom',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _TemplateList(
                    templates: _templateRepository.builtInTemplates,
                    isDark: isDark,
                    canDelete: false,
                  ),
                  _TemplateList(
                    templates: _templateRepository.customTemplates,
                    isDark: isDark,
                    canDelete: true,
                    onDelete: (id) async {
                      await _templateRepository.deleteCustomTemplate(id);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateList extends StatelessWidget {
  final List<PromptTemplate> templates;
  final bool isDark;
  final bool canDelete;
  final Function(String)? onDelete;

  const _TemplateList({
    required this.templates,
    required this.isDark,
    this.canDelete = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              canDelete ? Icons.note_add : Icons.inventory_2_outlined,
              size: 64,
              color: isDark ? AppTheme.slate600 : AppTheme.slate400,
            ),
            const SizedBox(height: 16),
            Text(
              canDelete ? 'No custom templates yet' : 'Built-in templates available',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDark ? AppTheme.slate400 : AppTheme.slate600,
              ),
            ),
            if (canDelete) ...[
              const SizedBox(height: 8),
              Text(
                'Create your first template to get started',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? AppTheme.slate500 : AppTheme.slate500,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _TemplateCard(
          template: template,
          isDark: isDark,
          canDelete: canDelete,
          onDelete: onDelete,
          onTest: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PromptPreviewScreen(
                  prompt: template.template,
                ),
              ),
            );
          },
          onEdit: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PromptBuilderScreen(),
              ),
            );
          },
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final PromptTemplate template;
  final bool isDark;
  final bool canDelete;
  final Function(String)? onDelete;
  final VoidCallback onTest;
  final VoidCallback onEdit;

  const _TemplateCard({
    required this.template,
    required this.isDark,
    required this.canDelete,
    this.onDelete,
    required this.onTest,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.slate700 : AppTheme.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTypeColor(template.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    template.type.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Text(
                      template.type.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              if (template.isBuiltIn)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bambooGreen600.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Built-in',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.bambooGreen600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            template.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? AppTheme.slate300 : AppTheme.slate600,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Difficulty Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(template.difficulty).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  template.difficulty.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _getDifficultyColor(template.difficulty),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Updated ${_formatDate(template.updatedAt)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? AppTheme.slate500 : AppTheme.slate400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTest,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(
                    'Test',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.bambooGreen600,
                    side: const BorderSide(color: AppTheme.bambooGreen600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!template.isBuiltIn) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : AppTheme.slate700,
                      side: BorderSide(
                        color: isDark ? AppTheme.slate600 : AppTheme.slate300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (canDelete && !template.isBuiltIn)
                IconButton(
                  onPressed: () => _showDeleteDialog(context),
                  icon: const Icon(Icons.delete_outline),
                  color: AppTheme.red600,
                ),
            ],
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

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return AppTheme.bambooGreen600;
      case Difficulty.medium:
        return AppTheme.blue600;
      case Difficulty.hard:
        return AppTheme.amber600;
      case Difficulty.expert:
        return AppTheme.red600;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Template',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${template.name}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call(template.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.red600,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}