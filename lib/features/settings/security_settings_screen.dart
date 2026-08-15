import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/security_provider.dart';
import '../../core/providers/groq_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/app_routes.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/pin_keypad.dart';
import '../../shared/widgets/dialogs/confirmation_dialog.dart';

import '../../core/services/dialog_service.dart';

/// Modern Security settings screen.
///
/// Sections:
/// * App Protection — PIN Lock toggle with live status
/// * PIN Settings — Change / Remove PIN (only when a PIN exists)
/// * App Lock — Lock Now (manual lock)
/// * API Configuration — separate from the PIN area
/// * Data Privacy — information only
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
              _buildPinProtectionCard(context, securityProvider),
              const SizedBox(height: AppTheme.spacing4),
              _buildAppLockCard(context, securityProvider),
              const SizedBox(height: AppTheme.spacing4),
              _buildApiCard(context),
              const SizedBox(height: AppTheme.spacing4),
              _buildPrivacyCard(context),
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
                  Text('App Protection', style: AppTheme.titleMedium),
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
  //  PIN Protection card — toggle + PIN settings
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildPinProtectionCard(BuildContext context, SecurityProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

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
                      color: AppTheme.bambooGreen600.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      Icons.pin_outlined,
                      color: AppTheme.bambooGreen600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PIN Lock', style: AppTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Protect QuizSnap with a PIN.',
                          style: AppTheme.bodySmall.copyWith(
                            color: colorScheme.onSurface
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
            SwitchListTile(
              title: const Text('PIN Lock'),
              subtitle: Text(
                provider.isPinEnabled
                    ? '● Enabled'
                    : '○ Disabled',
              ),
              value: provider.isPinEnabled,
              onChanged: provider.isLoading
                  ? null
                  : (value) async {
                      if (value) {
                        GoRouter.of(context).push(AppRoutes.setPin);
                      } else {
                        await _confirmDisablePin();
                      }
                    },
            ),
            if (provider.isPinEnabled) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit, color: AppTheme.blue600),
                title: const Text('Change PIN'),
                subtitle: const Text('Update your existing PIN'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showChangePinDialog(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.lock_open,
                  color: colorScheme.error,
                ),
                title: Text(
                  'Remove PIN',
                  style: TextStyle(color: colorScheme.error),
                ),
                subtitle: const Text('Disable PIN protection'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _confirmRemovePin(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  App Lock card — Lock Now
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildAppLockCard(BuildContext context, SecurityProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

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
                      color: AppTheme.amber600.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      Icons.lock_clock,
                      color: AppTheme.amber600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('App Lock', style: AppTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Manually lock QuizSnap.',
                          style: AppTheme.bodySmall.copyWith(
                            color: colorScheme.onSurface
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
              leading: Icon(
                provider.isPinEnabled
                    ? Icons.lock
                    : Icons.lock_open,
                color: provider.isPinEnabled ? colorScheme.primary : colorScheme.outline,
              ),
              title: const Text('Lock Now'),
              subtitle: Text(
                provider.isPinEnabled
                    ? 'Immediately lock the app with PIN'
                    : 'Set a PIN before locking QuizSnap',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: provider.isPinEnabled ? _confirmLockNow : _showSetPinRequiredDialog,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  API Configuration card
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildApiCard(BuildContext context) {
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
                      color: AppTheme.purple600.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(Icons.api, color: AppTheme.purple600, size: 22),
                  ),
                  const SizedBox(width: AppTheme.spacing3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('API Configuration', style: AppTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Groq API key for AI features',
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
                  onTap: () => GoRouter.of(context).push(AppRoutes.apiConfiguration),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Privacy card
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildPrivacyCard(BuildContext context) {
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
                      color: AppTheme.blue600.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: AppTheme.blue600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Privacy', style: AppTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Data handling and security practices',
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
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────────────

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
  //  Danger Zone
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

  // ─────────────────────────────────────────────────────────────────────
  //  Action dialogs / screens
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _confirmDisablePin() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Disable PIN Lock',
      message:
          'Are you sure you want to disable PIN lock? Your app will no longer be protected.',
      confirmAction: 'Disable',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final securityProvider = context.read<SecurityProvider>();
      await securityProvider.disablePin();

      if (!mounted) return;

      await DialogService.showInfo(context, 'PIN lock disabled');
    }
  }

  Future<void> _confirmRemovePin() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Remove PIN',
      message:
          'This will disable PIN lock. You can re-enable it at any time.',
      confirmAction: 'Remove',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final securityProvider = context.read<SecurityProvider>();
      await securityProvider.disablePin();

      if (!mounted) return;

      await DialogService.showInfo(context, 'PIN removed');
    }
  }

  void _showSetPinRequiredDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('PIN required'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
        ),
        contentPadding: const EdgeInsets.all(AppTheme.spacing6),
        content: const Text(
          'Set a PIN before locking QuizSnap.',
        ),
        actions: [
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
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    GoRouter.of(context).push(AppRoutes.setPin);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Set PIN'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLockNow() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Lock the app now?',
      message:
          'The app will be locked immediately and you will need to enter your PIN to continue.',
      confirmAction: 'Lock Now',
    );

    if (confirmed == true && mounted) {
      final securityProvider = context.read<SecurityProvider>();
      final currentRoute = GoRouterState.of(context).matchedLocation;
      securityProvider.setRouteBeforeLock(currentRoute);
      securityProvider.lockApp();
    }
  }

  void _showChangePinDialog() {
    final key = GlobalKey<_ChangePinDialogState>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ChangePinDialog(key: key),
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
              Text('• PIN lock: 4–6 digit numeric PIN'),
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
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Clear All Security Data',
      message:
          'This will remove your PIN, API keys, and all security settings. This action cannot be undone.',
      confirmAction: 'Clear All',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final securityProvider = context.read<SecurityProvider>();
      final groqProvider = context.read<GroqProvider>();

      await securityProvider.clearAllSecurityData();
      groqProvider.clearApiKey();

      if (!mounted) return;

      await DialogService.showSuccess(
        context,
        'All security data cleared',
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
//  Change PIN dialog with the same modern keypad
// ─────────────────────────────────────────────────────────────────────

class _ChangePinDialog extends StatefulWidget {
  const _ChangePinDialog({super.key});

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  String _oldPin = '';
  String _newPin = '';
  String? _errorText;
  bool _isLoading = false;
  int _step = 0; // 0 = old, 1 = new, 2 = confirm
  final _keypadKey = GlobalKey<PinKeypadState>();

  void _onChanged(String value) {
    if (_errorText != null) {
      setState(() => _errorText = null);
    }
  }

  Future<void> _onSubmit(String value) async {
    if (_step == 0) {
      if (value.length < 4) {
        setState(() => _errorText = 'Enter your current PIN.');
        return;
      }
      setState(() {
        _oldPin = value;
        _step = 1;
      });
      _keypadKey.currentState?.clear();
    } else if (_step == 1) {
      if (value.length < 4) {
        setState(() => _errorText = 'Your new PIN must contain 4–6 digits.');
        return;
      }
      setState(() {
        _newPin = value;
        _step = 2;
      });
      _keypadKey.currentState?.clear();
    } else {
      if (value != _newPin) {
        setState(() {
          _errorText = 'PINs do not match. Please try again.';
          _step = 1;
        });
        _keypadKey.currentState?.clear();
        return;
      }
      await _changePin();
    }
  }

  Future<void> _changePin() async {
    setState(() => _isLoading = true);
    final securityProvider = context.read<SecurityProvider>();
    final success = await securityProvider.changePin(_oldPin, _newPin);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      await DialogService.showSuccess(
        context,
        'PIN changed successfully',
      );
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      setState(() {
        _errorText = securityProvider.errorMessage ?? 'Failed to change PIN';
        _step = 0;
        _oldPin = '';
        _newPin = '';
      });
      _keypadKey.currentState?.clear();
    }
  }

  String _titleForStep() {
    switch (_step) {
      case 0:
        return 'Current PIN';
      case 1:
        return 'New PIN';
      case 2:
        return 'Confirm New PIN';
    }
    return '';
  }

  String _descriptionForStep() {
    switch (_step) {
      case 0:
        return 'Enter your current PIN.';
      case 1:
        return 'Enter a 4–6 digit PIN.';
      case 2:
        return 'Re-enter your new PIN.';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(_titleForStep()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
      ),
      contentPadding: const EdgeInsets.all(AppTheme.spacing6),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400,
            minWidth: 280,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _descriptionForStep(),
                style: AppTheme.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing4),
              PinKeypad(
                key: _keypadKey,
                maxLength: 6,
                minLength: 4,
                autoSubmit: true,
                errorText: _errorText,
                enabled: !_isLoading,
                onChanged: _onChanged,
                onSubmit: _onSubmit,
              ),
              const SizedBox(height: AppTheme.spacing4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  if (_step > 0)
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _step = _step > 0 ? _step - 1 : 0;
                                });
                                _keypadKey.currentState?.clear();
                              },
                        child: const Text('Back'),
                      ),
                    ),
                ],
              ),
              if (_isLoading) ...[
                const SizedBox(height: AppTheme.spacing4),
                const CircularProgressIndicator(strokeWidth: 2),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
