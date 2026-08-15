import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ai_quota_provider.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';
import '../../core/services/dialog_service.dart';

class AuthorizedQuotaScreen extends StatefulWidget {
  const AuthorizedQuotaScreen({super.key});

  @override
  State<AuthorizedQuotaScreen> createState() => _AuthorizedQuotaScreenState();
}

class _AuthorizedQuotaScreenState extends State<AuthorizedQuotaScreen> {
  late SecureStorageService _secureStorage;
  bool _isAuthEnabled = false;
  bool _isAuthenticated = false;
  DateTime? _lastModificationTime;

  @override
  void initState() {
    super.initState();
    _secureStorage = SecureStorageService();
    _loadAuthStatus();
  }

  Future<void> _loadAuthStatus() async {
    // Read the actual stored enabled state — this is the single source of
    // truth. The previous code hardcoded `true`, which caused the toggle
    // to have no effect.
    final isEnabled = await _secureStorage.isQuotaAuthEnabled();
    if (!mounted) return;

    final quotaProvider = context.read<AiQuotaProvider>();
    final lastMod = await quotaProvider.service.getLastModificationTime();

    if (!mounted) return;

    setState(() {
      _isAuthEnabled = isEnabled;
      _lastModificationTime = lastMod;
    });

    // Only show the authentication dialog if authorization is actually
    // enabled. When disabled, skip the password prompt entirely.
    if (isEnabled && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAuthenticationDialog();
      });
    } else {
      // Auth disabled — no password required to view the screen.
      setState(() {
        _isAuthenticated = true;
      });
    }
  }

  Future<void> _showAuthenticationDialog() async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authorization Required'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Enter Authorization Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the password';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              Navigator.pop(context); // Close the screen if cancelled
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Authorize'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final password = passwordController.text.trim();
      final isValid = await _secureStorage.verifyQuotaAuthPassword(password);
      if (isValid) {
        setState(() {
          _isAuthenticated = true;
        });
      } else {
        if (mounted) {
          await DialogService.showError(context, 'Invalid authorization password');
          if (!mounted) return;
          Navigator.pop(context); // Close the screen if password is wrong
        }
      }
    }
  }

  Future<void> _showPasswordDialog(String action, Future<bool> Function() actionCallback) async {
    // When authorization is disabled, skip the password prompt entirely
    // and execute the action directly.
    if (!_isAuthEnabled) {
      final success = await actionCallback();
      if (mounted) {
        if (success) {
          await DialogService.showSuccess(context, 'Action completed successfully');
        } else {
          await DialogService.showError(context, 'Action failed');
        }
        if (!mounted) return;
        context.read<AiQuotaProvider>().refreshQuota();
        final quotaProvider = context.read<AiQuotaProvider>();
        final lastMod = await quotaProvider.service.getLastModificationTime();
        setState(() {
          _lastModificationTime = lastMod;
        });
      }
      return;
    }

    // Authorization enabled — auto-authorize using the constant secret key.
    final success = await actionCallback();
    if (mounted) {
      if (success) {
        await DialogService.showSuccess(context, 'Action completed successfully');
      } else {
        await DialogService.showError(context, 'Action failed');
      }
      if (!mounted) return;
      // Refresh quota status
      context.read<AiQuotaProvider>().refreshQuota();
      // Reload last modification time
      final quotaProvider = context.read<AiQuotaProvider>();
      final lastMod = await quotaProvider.service.getLastModificationTime();
      setState(() {
        _lastModificationTime = lastMod;
      });
    }
  }

  /// Enables authorization: shows the password setup dialog and persists
  /// the enabled state. If the user cancels the dialog, the toggle reverts.
  Future<void> _enableAuthorization() async {
    final confirmed = await _setPasswordDialog();
    if (confirmed == true && mounted) {
      // Password was already stored inside the dialog; just flip the flag.
      await _secureStorage.setQuotaAuthEnabled(true);
      if (!mounted) return;
      setState(() {
        _isAuthEnabled = true;
      });
      await DialogService.showSuccess(context, 'Authorization enabled');
    } else if (mounted) {
      // User cancelled — revert the toggle visually.
      setState(() {
        _isAuthEnabled = false;
      });
    }
  }

  /// Disables authorization: persists the disabled state immediately so
  /// the toggle is the single source of truth. No password is required
  /// to disable.
  Future<void> _disableAuthorization() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Authorization'),
        content: const Text('Are you sure you want to disable quota authorization? Anyone will be able to modify quota settings.'),
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
      // Persist the disabled state immediately — this is the single source
      // of truth that survives app restart, navigation, theme change, and
      // rotation.
      await _secureStorage.clearQuotaAuthPassword();
      await _secureStorage.setQuotaAuthEnabled(false);
      if (!mounted) return;
      setState(() {
        _isAuthEnabled = false;
      });
      await DialogService.showInfo(context, 'Authorization disabled');
    }
  }

  /// Shows the password setup dialog and stores the password if confirmed.
  /// Returns true if the user confirmed, false if cancelled.
  Future<bool?> _setPasswordDialog() async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Authorization Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 4) {
                    return 'Password must be at least 4 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm the password';
                  }
                  if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Set Password'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _secureStorage.storeQuotaAuthPassword(passwordController.text.trim());
    }
    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return const Scaffold(
        appBar: CustomAppBar(
          title: 'Authorized Quota Management',
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Authorized Quota Management',
      ),
      body: Consumer<AiQuotaProvider>(
        builder: (context, quotaProvider, _) {
          final status = quotaProvider.quotaStatus;
          
          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            children: [
              // Authorization status card
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: AppTheme.bambooGreen600,
                          size: 32,
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quota Status',
                                style: AppTheme.headlineSmall,
                              ),
                              const SizedBox(height: AppTheme.spacingXs),
                              Text(
                                _isAuthEnabled ? 'Authorization Enabled' : 'Authorization Disabled',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: _isAuthEnabled ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.tertiary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isAuthEnabled,
                          onChanged: (value) {
                            if (value) {
                              _enableAuthorization();
                            } else {
                              _disableAuthorization();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Text(
                      'Current Quota Status',
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _buildQuotaDetail('Used', '${status?.used ?? 0} requests'),
                    _buildQuotaDetail('Remaining', '${status?.remaining ?? 0} requests'),
                    _buildQuotaDetail('Daily Limit', '${status?.limit ?? 0} requests'),
                    if (_lastModificationTime != null) ...[
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        'Last modified: ${_formatDateTime(_lastModificationTime!)}',
                        style: AppTheme.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              
              // Authorized actions
              Text(
                'Authorized Actions',
                style: AppTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _buildActionCard(
                context,
                title: 'Increase Quota',
                description: 'Add more requests to today\'s quota',
                icon: Icons.add_circle,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => _showIncreaseQuotaDialog(),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _buildActionCard(
                context,
                title: 'Decrease Quota',
                description: 'Reduce today\'s quota limit',
                icon: Icons.remove_circle,
                color: Theme.of(context).colorScheme.tertiary,
                onTap: () => _showDecreaseQuotaDialog(),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _buildActionCard(
                context,
                title: 'Reset Today\'s Usage',
                description: 'Reset usage count to zero',
                icon: Icons.refresh,
                color: Theme.of(context).colorScheme.secondary,
                onTap: () => _showPasswordDialog('Reset Usage', () async {
                  final quotaProvider = context.read<AiQuotaProvider>();
                  return await quotaProvider.service.resetTodayUsage();
                }),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _buildActionCard(
                context,
                title: 'Set Custom Limit',
                description: 'Set a specific daily limit',
                icon: Icons.tune,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                onTap: () => _showCustomLimitDialog(),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _buildActionCard(
                context,
                title: 'Restore Default',
                description: 'Restore the default 15 request limit',
                icon: Icons.restore,
                color: Theme.of(context).colorScheme.error,
                onTap: () => _showPasswordDialog('Restore Default', () async {
                  final quotaProvider = context.read<AiQuotaProvider>();
                  return await quotaProvider.service.restoreDefaultLimit();
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuotaDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium,
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  description,
                  style: AppTheme.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Future<void> _showIncreaseQuotaDialog() async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Increase Quota'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount to add',
              border: OutlineInputBorder(),
              suffixText: 'requests',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              final amount = int.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid positive number';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Increase'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final amount = int.parse(amountController.text.trim());
      await _showPasswordDialog('Increase Quota', () async {
        final quotaProvider = context.read<AiQuotaProvider>();
        return await quotaProvider.service.increaseQuota(amount);
      });
    }
  }

  Future<void> _showDecreaseQuotaDialog() async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decrease Quota'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount to remove',
              border: OutlineInputBorder(),
              suffixText: 'requests',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              final amount = int.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid positive number';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Decrease'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final amount = int.parse(amountController.text.trim());
      await _showPasswordDialog('Decrease Quota', () async {
        final quotaProvider = context.read<AiQuotaProvider>();
        return await quotaProvider.service.decreaseQuota(amount);
      });
    }
  }

  Future<void> _showCustomLimitDialog() async {
    final limitController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Custom Limit'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: limitController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Daily limit',
              border: OutlineInputBorder(),
              suffixText: 'requests',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a limit';
              }
              final limit = int.tryParse(value);
              if (limit == null || limit <= 0) {
                return 'Please enter a valid positive number';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Set Limit'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final limit = int.parse(limitController.text.trim());
      await _showPasswordDialog('Set Custom Limit', () async {
        final quotaProvider = context.read<AiQuotaProvider>();
        return await quotaProvider.service.setCustomDailyLimit(limit);
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}