import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/groq_provider.dart';
import '../../core/providers/ai_quota_provider.dart';
import '../../core/models/recent_generation.dart';
import '../../core/repositories/recent_generation_repository.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import 'file_picker_bottom_sheet.dart';
import 'camera_ocr_screen.dart';
import 'recent_generation_details_screen.dart';

class AiGenerateHomeScreen extends StatefulWidget {
  const AiGenerateHomeScreen({super.key});

  @override
  State<AiGenerateHomeScreen> createState() => _AiGenerateHomeScreenState();
}

class _AiGenerateHomeScreenState extends State<AiGenerateHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'AI Generate'),
      body: Consumer<GroqProvider>(
        builder: (context, groqProvider, _) {
          // Show loading state during auto-initialization
          if (groqProvider.isAutoInitializing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing AI service...'),
                ],
              ),
            );
          }

          // Show API key setup if not initialized
          if (!groqProvider.isInitialized) {
            return _buildApiKeySetup(context, groqProvider);
          }

          return _buildImportOptions(context, groqProvider);
        },
      ),
    );
  }

  Widget _buildApiKeySetup(BuildContext context, GroqProvider groqProvider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.smart_toy_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Text(
                  'AI setup required',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'QuizSnap needs an AI API key before it can generate questions.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'If you do not have an API key, contact your system administrator '
                  'or the person responsible for configuring QuizSnap.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _navigateToApiConfig(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Later'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.key),
                        label: const Text('Configure API Key'),
                        onPressed: () => _navigateToApiConfig(context),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToApiConfig(BuildContext context) {
    GoRouter.of(context).push(AppRoutes.apiConfiguration);
  }

  Widget _buildImportOptions(BuildContext context, GroqProvider groqProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quota display
          Consumer<AiQuotaProvider>(
            builder: (context, quotaProvider, _) {
              return _buildQuotaDisplay(context, quotaProvider);
            },
          ),
          const SizedBox(height: 24),
          
          Text(
            'Import Document',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a document type to import and generate questions from',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
                children: [
                  _buildImportCard(
                    context,
                    title: 'PDF',
                    icon: Icons.picture_as_pdf,
                    color: const Color(0xFFEF4444), // Red
                    onTap: () => _showFilePicker(context, 'pdf'),
                  ),
                  _buildImportCard(
                    context,
                    title: 'TXT',
                    icon: Icons.text_snippet,
                    color: const Color(0xFF64748B), // Slate
                    onTap: () => _showFilePicker(context, 'txt'),
                  ),
                  _buildImportCard(
                    context,
                    title: 'DOCX',
                    icon: Icons.description,
                    color: const Color(0xFF3B82F6), // Blue
                    onTap: () => _showFilePicker(context, 'docx'),
                  ),
                  _buildImportCard(
                    context,
                    title: 'Camera OCR',
                    icon: Icons.camera_alt,
                    color: const Color(0xFF22C55E), // Green
                    onTap: () => _navigateToCameraOCR(context),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Generations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Consumer<RecentGenerationRepository>(
            builder: (context, repo, _) {
              final generations = repo.generations;
              if (generations.isEmpty) {
                return const EmptyState(
                  icon: Icons.history,
                  title: 'No recent generations',
                  subtitle: 'Your recently generated questions will appear here',
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: generations.length,
                itemBuilder: (context, index) {
                  final gen = generations[index];
                  return CustomCard(
                    onTap: () => _openRecentGeneration(context, gen),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gen.title,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${gen.questionCount} questions • ${gen.savedDeckId != null ? 'Saved' : 'Unsaved'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  void _showFilePicker(BuildContext context, String fileType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilePickerBottomSheet(fileType: fileType),
    );
  }

  void _navigateToCameraOCR(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CameraOcrScreen(),
      ),
    );
  }

  Widget _buildQuotaDisplay(BuildContext context, AiQuotaProvider quotaProvider) {
    final status = quotaProvider.quotaStatus;
    if (status == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status.isLow
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            status.isLow ? Icons.warning : Icons.check_circle,
            color: status.isLow
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Quota: ${status.displayText} remaining today',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: status.isLow
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: status.isLow
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openRecentGeneration(BuildContext context, RecentGeneration gen) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecentGenerationDetailsScreen(generation: gen),
      ),
    );
  }
}