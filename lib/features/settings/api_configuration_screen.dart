import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/groq_provider.dart';
import '../../core/models/groq_models.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../core/services/dialog_service.dart';

class ApiConfigurationScreen extends StatefulWidget {
  const ApiConfigurationScreen({super.key});

  @override
  State<ApiConfigurationScreen> createState() => _ApiConfigurationScreenState();
}

class _ApiConfigurationScreenState extends State<ApiConfigurationScreen> {
  final _apiKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureKey = true;
  bool _hasChanges = false;
  String? _maskedApiKey;
  late final SecureStorageService _secureStorage;

  @override
  void initState() {
    super.initState();
    _secureStorage = SecureStorageService();
    _loadExistingKey();
  }

  Future<void> _loadExistingKey() async {
    // We don't load the actual key for security, just check if it exists
    // The key is loaded from secure storage when needed
    final groqProvider = context.read<GroqProvider>();
    if (!groqProvider.hasAttemptedAutoInit) {
      await groqProvider.retryInitialization();
    }
    
    // Load masked API key for display
    _maskedApiKey = await _secureStorage.getMaskedGroqApiKey();
    
    // Update UI to show if key is configured
    setState(() {});
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    final groqProvider = context.read<GroqProvider>();
    final apiKey = _apiKeyController.text.trim();

    final success = await groqProvider.testConnection(apiKey);

    if (!mounted) return;

    if (success) {
      await DialogService.showSuccess(context, 'Connection successful!');
    } else {
      await DialogService.showError(context, 'Connection failed: ${groqProvider.errorMessage}');
    }
  }

  Future<void> _saveApiKey() async {
    if (!_formKey.currentState!.validate()) return;

    final groqProvider = context.read<GroqProvider>();
    final apiKey = _apiKeyController.text.trim();

    final success = await groqProvider.initialize(apiKey);

    if (!mounted) return;

    if (success) {
      await DialogService.showSuccess(context, 'API key saved successfully!');
      setState(() {
        _hasChanges = false;
      });
      _apiKeyController.clear();
    } else {
      await DialogService.showError(context, 'Failed to save API key: ${groqProvider.errorMessage}');
    }
  }

  Future<void> _clearApiKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear API Key'),
        content: const Text('Are you sure you want to remove your API key? This will disable AI features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final groqProvider = context.read<GroqProvider>();
      groqProvider.clearApiKey();

      // Clear the local masked key so the UI immediately reflects the
      // cleared state without requiring navigation away and back.
      setState(() {
        _maskedApiKey = null;
        _hasChanges = false;
        _apiKeyController.clear();
      });

      await DialogService.showSuccess(context, 'API key cleared');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'API Configuration',
      ),
      body: Consumer<GroqProvider>(
        builder: (context, groqProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.api,
                            color: AppTheme.bambooGreen600,
                            size: 32,
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Groq API Key',
                                  style: AppTheme.headlineSmall,
                                ),
                                const SizedBox(height: AppTheme.spacingXs),
                                Text(
                                  'Enter your Groq API key to enable AI features',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (groqProvider.isInitialized)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingSm,
                                vertical: AppTheme.spacingXs,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: Theme.of(context).colorScheme.primary),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Configured',
                                    style: AppTheme.labelSmall.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      if (_maskedApiKey != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: AppTheme.bambooGreen600.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.key,
                                color: AppTheme.bambooGreen600,
                                size: 20,
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'API Key Configured',
                                      style: AppTheme.labelMedium.copyWith(
                                        color: AppTheme.bambooGreen600,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacingXs),
                                    Text(
                                      _maskedApiKey!,
                                      style: AppTheme.bodySmall.copyWith(
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        Text(
                          'Update API Key',
                          style: AppTheme.labelLarge,
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                      ],
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _apiKeyController,
                              obscureText: _obscureKey,
                              onChanged: (value) {
                                setState(() {
                                  _hasChanges = value.isNotEmpty;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'API Key',
                                hintText: 'gsk_...',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureKey ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureKey = !_obscureKey;
                                    });
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your API key';
                                }
                                if (!value.startsWith('gsk_')) {
                                  return 'Invalid API key format';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: 'Test Connection',
                                    onPressed: groqProvider.isLoading ? null : _testConnection,
                                    isOutlined: true,
                                    isLoading: groqProvider.isLoading,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingMd),
                                Expanded(
                                  child: CustomButton(
                                    text: 'Save API Key',
                                    onPressed: _hasChanges ? _saveApiKey : null,
                                    isLoading: groqProvider.isLoading,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              if (groqProvider.isInitialized) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Model Selection',
                          style: AppTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          'Selected: ${groqProvider.selectedModel}',
                          style: AppTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        DropdownButtonFormField<String>(
                          initialValue: groqProvider.selectedModel,
                          decoration: const InputDecoration(
                            labelText: 'AI Model',
                            border: OutlineInputBorder(),
                          ),
                          items: GroqModels.supportedModels.map((model) {
                            return DropdownMenuItem(
                              value: model,
                              child: Text(GroqModels.getDisplayName(model)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              groqProvider.setSelectedModel(value);
                            }
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          '${GroqModels.getDisplayName(GroqModels.getDefaultModel())} is recommended for best performance',
                          style: AppTheme.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'API Key Management',
                          style: AppTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        ListTile(
                          leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                          title: const Text('Clear API Key'),
                          subtitle: const Text('Remove your API key from secure storage'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _clearApiKey,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacingLg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Information',
                        style: AppTheme.titleLarge,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildSecurityItem(
                        icon: Icons.lock,
                        title: 'Encrypted Storage',
                        description: 'Your API key is stored using Flutter Secure Storage with encryption',
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      _buildSecurityItem(
                        icon: Icons.cloud_off,
                        title: 'Local Only',
                        description: 'Your API key never leaves your device except for API calls to Groq',
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      _buildSecurityItem(
                        icon: Icons.security,
                        title: 'No Tracking',
                        description: 'We do not track or store your API usage',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.bambooGreen600, size: 20),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.labelMedium,
              ),
              Text(
                description,
                style: AppTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
