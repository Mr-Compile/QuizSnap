import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/groq_provider.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/empty_state.dart';
import 'file_picker_bottom_sheet.dart';
import 'camera_ocr_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Generate'),
        elevation: 0,
      ),
      body: Consumer<GroqProvider>(
        builder: (context, groqProvider, _) {
          if (!groqProvider.isInitialized) {
            return _buildApiKeySetup(context, groqProvider);
          }

          return _buildImportOptions(context);
        },
      ),
    );
  }

  Widget _buildApiKeySetup(BuildContext context, GroqProvider groqProvider) {
    return Center(
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter an API key')),
                          );
                          return;
                        }

                        final success = await groqProvider.initialize(apiKey);
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(groqProvider.errorMessage ?? 'Failed to initialize')),
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
            TextButton(
              onPressed: () {
                // TODO: Open help documentation
              },
              child: const Text('How to get an API key?'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportOptions(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                color: Colors.red,
                onTap: () => _showFilePicker(context, 'pdf'),
              ),
              _buildImportCard(
                context,
                title: 'TXT',
                icon: Icons.text_snippet,
                color: Colors.green,
                onTap: () => _showFilePicker(context, 'txt'),
              ),
              _buildImportCard(
                context,
                title: 'Camera OCR',
                icon: Icons.camera_alt,
                color: Colors.purple,
                onTap: () => _navigateToCameraOCR(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Generations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const EmptyState(
            icon: Icons.history,
            title: 'No recent generations',
            subtitle: 'Your recently generated questions will appear here',
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
}