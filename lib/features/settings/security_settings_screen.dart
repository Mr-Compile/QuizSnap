import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/security_provider.dart';
import '../../core/providers/groq_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import 'api_configuration_screen.dart';
import 'set_pin_screen.dart';
import '../../core/services/dialog_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  @override
  void initState() {
    super.initState();
    _initializeSecurity();
  }

  Future<void> _initializeSecurity() async {
    if (!mounted) return;
    final securityProvider = context.read<SecurityProvider>();
    await securityProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Security',
      ),
      body: Consumer<SecurityProvider>(
        builder: (context, securityProvider, child) {
          return ListView(
            children: [
              _buildSection(
                title: 'App Lock',
                children: [
                  SwitchListTile(
                    title: const Text('PIN Lock'),
                    subtitle: Text(securityProvider.isPinEnabled 
                        ? 'PIN lock is enabled' 
                        : 'Require PIN to open the app'),
                    value: securityProvider.isPinEnabled,
                    onChanged: securityProvider.isLoading 
                        ? null 
                        : (value) async {
                            if (value) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SetPinScreen(),
                                ),
                              );
                            } else {
                              await _confirmDisablePin();
                            }
                          },
                  ),
                  if (securityProvider.isPinEnabled)
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Change PIN'),
                      subtitle: const Text('Update your current PIN'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showChangePinDialog(),
                    ),
                  if (securityProvider.isPinEnabled)
                    ListTile(
                      leading: const Icon(Icons.lock_clock),
                      title: const Text('Lock Now'),
                      subtitle: const Text('Immediately lock the app with PIN'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        securityProvider.lockApp();
                      },
                    ),
                ],
              ),
              _buildSection(
                title: 'API Configuration',
                children: [
                  Consumer<GroqProvider>(
                    builder: (context, groqProvider, child) {
                      return ListTile(
                        leading: const Icon(Icons.api),
                        title: const Text('Groq API Key'),
                        subtitle: Text(groqProvider.isInitialized 
                            ? 'API key is configured' 
                            : 'Configure your Groq API key'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ApiConfigurationScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              _buildSection(
                title: 'Privacy',
                children: [
                  ListTile(
                    leading: const Icon(Icons.shield),
                    title: const Text('Data Privacy'),
                    subtitle: const Text('Learn how we protect your data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPrivacyDialog(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Security Information'),
                    subtitle: const Text('View security features and practices'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showSecurityInfoDialog(),
                  ),
                ],
              ),
              _buildSection(
                title: 'Danger Zone',
                children: [
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
                    title: const Text('Clear All Security Data'),
                    subtitle: const Text('Remove PIN, API keys, and all security settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _confirmClearAllSecurityData(),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Text(
            title,
            style: AppTheme.labelLarge.copyWith(
              color: AppTheme.bambooGreen600,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Future<void> _confirmDisablePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable PIN Lock'),
        content: const Text('Are you sure you want to disable PIN lock? Your app will no longer be protected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final securityProvider = context.read<SecurityProvider>();
      await securityProvider.disablePin();
      
      if (!mounted) return;
      
      await DialogService.showInfo(context, 'PIN lock disabled');
    }
  }

  void _showChangePinDialog() {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change PIN'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Current PIN',
                  hintText: '••••',
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter current PIN';
                  }
                  if (value.length != 4) {
                    return 'PIN must be 4 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'New PIN',
                  hintText: '••••',
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter new PIN';
                  }
                  if (value.length != 4) {
                    return 'PIN must be 4 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Confirm New PIN',
                  hintText: '••••',
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm new PIN';
                  }
                  if (value != newPinController.text) {
                    return 'PINs do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          Consumer<SecurityProvider>(
            builder: (context, securityProvider, child) {
              return ElevatedButton(
                onPressed: securityProvider.isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        
                        final success = await securityProvider.changePin(
                          oldPinController.text,
                          newPinController.text,
                        );
                        
                        if (!mounted) return;

                        if (success) {
                          // ignore: use_build_context_synchronously
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          await DialogService.showSuccess(context, 'PIN changed successfully');
                        } else {
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          await DialogService.showError(context, securityProvider.errorMessage ?? 'Failed to change PIN');
                        }
                      },
                child: securityProvider.isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change PIN'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Privacy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your data is stored locally on your device.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• All flashcards, decks, and study data are stored in a local SQLite database'),
              Text('• API keys are encrypted using Flutter Secure Storage'),
              Text('• PINs are hashed using SHA-256 before storage'),
              Text('• We do not collect or transmit your personal data'),
              Text('• No account or internet connection required'),
              SizedBox(height: 16),
              Text(
                'AI Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• When using AI features, only the content you provide is sent to Groq'),
              Text('• Your API key is used directly with Groq\'s servers'),
              Text('• We do not store or log your AI requests'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSecurityInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Information'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Encryption & Storage',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• API keys: Encrypted with AES-256 via Flutter Secure Storage'),
              Text('• PINs: Hashed with SHA-256'),
              Text('• Database: Local SQLite with optional backup encryption'),
              SizedBox(height: 16),
              Text(
                'Authentication',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• PIN lock: 4-digit numeric PIN'),
              Text('• Failed attempt protection after 3 incorrect tries'),
              SizedBox(height: 16),
              Text(
                'Best Practices',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Use a unique PIN you can remember'),
              Text('• Keep your device OS updated'),
              Text('• Regularly backup your data'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAllSecurityData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Security Data'),
        content: const Text(
          'This will remove:\n'
          '• Your PIN\n'
          '• API keys\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final securityProvider = context.read<SecurityProvider>();
      final groqProvider = context.read<GroqProvider>();
      
      securityProvider.clearAllSecurityData();
      groqProvider.clearApiKey();
      
      await DialogService.showSuccess(context, 'All security data cleared');
    }
  }
}
