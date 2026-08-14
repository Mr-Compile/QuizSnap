import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/security_provider.dart';
import '../../core/providers/groq_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing4,
              vertical: AppTheme.spacing4,
            ),
            children: [
              _buildSecurityStatusCard(context, securityProvider),
              const SizedBox(height: AppTheme.spacing4),
              _buildSectionCard(
                context: context,
                title: 'App Lock',
                description: 'PIN protection for app access',
                icon: Icons.lock_outline,
                iconColor: AppTheme.red600,
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
                  if (securityProvider.isPinEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Change PIN'),
                      subtitle: const Text('Update your current PIN'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showChangePinDialog(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock_clock),
                      title: const Text('Lock Now'),
                      subtitle: const Text('Immediately lock the app with PIN'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _confirmLockNow(),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppTheme.spacing4),
              _buildSectionCard(
                context: context,
                title: 'API Configuration',
                description: 'Groq API key for AI features',
                icon: Icons.api,
                iconColor: AppTheme.purple600,
                children: [
                  Consumer<GroqProvider>(
                    builder: (context, groqProvider, child) {
                      return ListTile(
                        leading: const Icon(Icons.api),
                        title: const Text('Groq API Key'),
                        subtitle: Text(groqProvider.isInitialized
                            ? 'API key is configured'
                            : 'Configure your Groq API key'),
                        trailing: groqProvider.isInitialized
                            ? _buildStatusChip(
                                context, 'Active', AppTheme.bambooGreen600)
                            : _buildStatusChip(
                                context, 'Not Set', AppTheme.orange600),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ApiConfigurationScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing4),
              _buildSectionCard(
                context: context,
                title: 'Privacy',
                description: 'Data handling and security practices',
                icon: Icons.shield_outlined,
                iconColor: AppTheme.blue600,
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Data Privacy'),
                    subtitle: const Text('Learn how we protect your data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPrivacyDialog(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Security Information'),
                    subtitle: const Text('View security features and practices'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showSecurityInfoDialog(),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing4),
              _buildDangerZone(context),
              const SizedBox(height: AppTheme.spacing6),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Top security status card
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildSecurityStatusCard(
      BuildContext context, SecurityProvider provider) {
    final isProtected = provider.isPinEnabled;
    final statusColor = isProtected ? AppTheme.bambooGreen600 : AppTheme.orange600;
    final statusIcon = isProtected ? Icons.verified_user : Icons.warning_amber;
    final statusText = isProtected ? 'Protected' : 'Not Protected';
    final statusDesc = isProtected
        ? 'PIN lock is enabled. Your app is secured.'
        : 'Enable PIN lock to protect your app.';

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(statusIcon, color: statusColor, size: 32),
            ),
            const SizedBox(width: AppTheme.spacing4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusText, style: AppTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    statusDesc,
                    style: AppTheme.bodySmall.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusChip(context, statusText, statusColor),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Section card builder
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacing4,
                AppTheme.spacing3,
                AppTheme.spacing4,
                AppTheme.spacing2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: AppTheme.spacing3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: AppTheme.bodySmall.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing2,
        vertical: AppTheme.spacing1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTheme.labelSmall.copyWith(color: color),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Danger Zone — visually separated destructive actions
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDangerZone(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Container(
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: errorColor.withValues(alpha: 0.2)),
      ),
      child: CustomCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacing4,
                  AppTheme.spacing3,
                  AppTheme.spacing4,
                  AppTheme.spacing2,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: errorColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(Icons.dangerous_outlined,
                          color: errorColor, size: 22),
                    ),
                    const SizedBox(width: AppTheme.spacing3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Danger Zone',
                              style: AppTheme.titleMedium.copyWith(
                                  color: errorColor)),
                          const SizedBox(height: 2),
                          Text(
                            'Irreversible actions — proceed with caution',
                            style: AppTheme.bodySmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.delete_forever, color: errorColor),
                title: const Text('Clear All Security Data'),
                subtitle: const Text(
                    'Remove PIN, API keys, and all security settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _confirmClearAllSecurityData(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDisablePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable PIN Lock'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
        ),
        contentPadding: const EdgeInsets.all(AppTheme.spacing6),
        content: const Text('Are you sure you want to disable PIN lock? Your app will no longer be protected.'),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppTheme.spacing4),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Disable'),
                ),
              ),
            ],
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

  /// Confirmation dialog for the "Lock Now" action.
  ///
  /// Locks the app immediately on confirmation.  The GoRouter redirect
  /// logic in [main.dart] detects the locked state and routes to the
  /// PIN lock screen.  The current route is preserved by
  /// [SecurityProvider.setRouteBeforeLock] so the user returns to the
  /// same screen after unlock.
  Future<void> _confirmLockNow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lock the app now?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
        ),
        contentPadding: const EdgeInsets.all(AppTheme.spacing6),
        content: const Text(
          'The app will be locked immediately and you will need to enter your PIN to continue.',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppTheme.spacing4),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.lock),
                  label: const Text('Lock Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Save the current route so it can be restored after unlock.
      final securityProvider = context.read<SecurityProvider>();
      final currentRoute = GoRouterState.of(context).matchedLocation;
      securityProvider.setRouteBeforeLock(currentRoute);
      securityProvider.lockApp();
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
        ),
        contentPadding: const EdgeInsets.all(AppTheme.spacing6),
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
              const SizedBox(height: AppTheme.spacing4),
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
              const SizedBox(height: AppTheme.spacing4),
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
          // Action buttons in one horizontal row: Cancel (outlined, left)
          // and Change PIN (primary, right).
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppTheme.spacing4),
              Expanded(
                child: Consumer<SecurityProvider>(
                  builder: (context, securityProvider, child) {
                    return FilledButton(
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
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
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
              ),
            ],
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
              Text('• Brute-force protection: 30s lockout after 5 failed attempts'),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
        ),
        contentPadding: const EdgeInsets.all(AppTheme.spacing6),
        content: const Text(
          'This will remove:\n'
          '• Your PIN\n'
          '• API keys\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppTheme.spacing4),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Clear All'),
                ),
              ),
            ],
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
