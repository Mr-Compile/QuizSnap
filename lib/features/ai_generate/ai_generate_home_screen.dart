import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/groq_provider.dart';
import '../../core/providers/ai_quota_provider.dart';
import '../../core/providers/notification_service.dart';
import '../../core/models/recent_generation.dart';
import '../../core/repositories/recent_generation_repository.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import 'file_picker_bottom_sheet.dart';
import 'camera_ocr_screen.dart';
import 'cached_documents_screen.dart';
import 'recent_generation_details_screen.dart';
import 'recent_documents_section.dart';

class AiGenerateHomeScreen extends StatefulWidget {
  const AiGenerateHomeScreen({super.key});

  @override
  State<AiGenerateHomeScreen> createState() => _AiGenerateHomeScreenState();
}

class _AiGenerateHomeScreenState extends State<AiGenerateHomeScreen> {
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroqProvider>(
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
    );
  }

  Widget _buildApiKeySetup(BuildContext context, GroqProvider groqProvider) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.api_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Setup Groq API Key',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your Groq API key to enable AI-powered question generation',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'gsk_...',
                  border: const OutlineInputBorder(),
                  errorText: groqProvider.errorMessage,
                ),
                onChanged: (value) {
                  groqProvider.clearError();
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: groqProvider.isLoading
                      ? null
                      : () async {
                          final apiKey = _apiKeyController.text.trim();
                          
                          if (apiKey.isEmpty) {
                            groqProvider.clearError();
                            context.read<NotificationService>().showErrorTop('Please enter an API key');
                            return;
                          }

                          final notifier = context.read<NotificationService>();
                          final success = await groqProvider.initialize(apiKey);
                          if (!success && mounted) {
                            notifier.showErrorTop(
                              groqProvider.errorMessage ?? 'Failed to initialize',
                            );
                          }
                        },
                  child: groqProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Connect'),
                ),
              ),
              const SizedBox(height: 16),
              if (groqProvider.errorMessage != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        groqProvider.retryInitialization();
                      },
                      child: const Text('Retry from saved key'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              TextButton(
                onPressed: () {
                  _showApiKeyHelpDialog(context);
                },
                child: const Text('How to get an API key?'),
              ),
            ],
          ),
        ),
      ),
    );
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
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildImportCard(
                context,
                title: 'PDF',
                icon: Icons.picture_as_pdf,
                color: Theme.of(context).colorScheme.error,
                onTap: () => _showFilePicker(context, 'pdf'),
              ),
              _buildImportCard(
                context,
                title: 'TXT',
                icon: Icons.text_snippet,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => _showFilePicker(context, 'txt'),
              ),
              _buildImportCard(
                context,
                title: 'DOCX',
                icon: Icons.description,
                color: Theme.of(context).colorScheme.secondary,
                onTap: () => _showFilePicker(context, 'docx'),
              ),
              _buildImportCard(
                context,
                title: 'Cached Documents',
                icon: Icons.folder_open,
                color: Theme.of(context).colorScheme.tertiary,
                onTap: () => _showCachedDocuments(context),
              ),
              _buildImportCard(
                context,
                title: 'Camera OCR',
                icon: Icons.camera_alt,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                onTap: () => _navigateToCameraOCR(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const RecentDocumentsSection(),
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

  void _showCachedDocuments(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CachedDocumentsScreen(),
      ),
    );
  }

  void _showApiKeyHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to get a Groq API Key'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Visit console.groq.com',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('2. Sign up or log in to your account'),
              SizedBox(height: 8),
              Text('3. Navigate to the API Keys section'),
              SizedBox(height: 8),
              Text('4. Click "Create API Key"'),
              SizedBox(height: 8),
              Text('5. Copy your API key and paste it here'),
              SizedBox(height: 16),
              Text(
                'Your API key is stored securely on your device.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}