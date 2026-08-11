import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ai_quota_provider.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_card.dart';

class AuthorizedQuotaScreen extends StatefulWidget {
  const AuthorizedQuotaScreen({super.key});

  @override
  State<AuthorizedQuotaScreen> createState() => _AuthorizedQuotaScreenState();
}

class _AuthorizedQuotaScreenState extends State<AuthorizedQuotaScreen> {
  late final SecureStorageService _secureStorage;
  bool _isAuthEnabled = false;
  DateTime? _lastModificationTime;

  @override
  void initState() {
    super.initState();
    _secureStorage = SecureStorageService();
    _loadAuthStatus();
  }

  Future<void> _loadAuthStatus() async {
    final isEnabled = await _secureStorage.isQuotaAuthEnabled();
    if (!mounted) return;
    
    final quotaProvider = context.read<AiQuotaProvider>();
    final lastMod = await quotaProvider.service.getLastModificationTime();
    
    if (!mounted) return;
    
    setState(() {
      _isAuthEnabled = isEnabled;
      _lastModificationTime = lastMod;
    });
  }

  Future<void> _showPasswordDialog(String action, Future<bool> Function() actionCallback) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Authorize $action'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Authorization Password',
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
            onPressed: () => Navigator.pop(context, false),
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
        final success = await actionCallback();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Action completed successfully' : 'Action failed'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
          // Refresh quota status
          context.read<AiQuotaProvider>().refreshQuota();
          // Reload last modification time
          final quotaProvider = context.read<AiQuotaProvider>();
          final lastMod = await quotaProvider.service.getLastModificationTime();
          setState(() {
            _lastModificationTime = lastMod;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid authorization password'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _setPassword() async {
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
      await _secureStorage.setQuotaAuthEnabled(true);
      if (!mounted) return;
      setState(() {
        _isAuthEnabled = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authorization password set successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _secureStorage.clearQuotaAuthPassword();
      await _secureStorage.setQuotaAuthEnabled(false);
      if (!mounted) return;
      setState(() {
        _isAuthEnabled = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authorization disabled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          _isAuthEnabled ? Icons.security : Icons.lock_open,
                          color: _isAuthEnabled ? Colors.green : Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Authorization Status',
                                style: AppTheme.titleMedium,
                              ),
                              const SizedBox(height: AppTheme.spacingXs),
                              Text(
                                _isAuthEnabled ? 'Enabled' : 'Disabled',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: _isAuthEnabled ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    if (_isAuthEnabled) ...[
                      Text(
                        'Password protection is active. Authorization is required for quota modifications.',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Authorization is disabled. Anyone can modify quota settings.',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isAuthEnabled ? _disableAuthorization : _setPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isAuthEnabled ? Colors.red : Colors.green,
                            ),
                            child: Text(_isAuthEnabled ? 'Disable' : 'Enable'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              
              // Current quota status
              if (status != null) ...[
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Quota Status',
                        style: AppTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildQuotaDetail('Used', '${status.used} requests'),
                      _buildQuotaDetail('Remaining', '${status.remaining} requests'),
                      _buildQuotaDetail('Daily Limit', '${status.limit} requests'),
                      if (_lastModificationTime != null) ...[
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          'Last modified: ${_formatDateTime(_lastModificationTime!)}',
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
              ],
              
              // Authorized actions
              if (_isAuthEnabled) ...[
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
                  color: Colors.green,
                  onTap: () => _showIncreaseQuotaDialog(),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _buildActionCard(
                  context,
                  title: 'Decrease Quota',
                  description: 'Reduce today\'s quota limit',
                  icon: Icons.remove_circle,
                  color: Colors.orange,
                  onTap: () => _showDecreaseQuotaDialog(),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _buildActionCard(
                  context,
                  title: 'Reset Today\'s Usage',
                  description: 'Reset usage count to zero',
                  icon: Icons.refresh,
                  color: Colors.blue,
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
                  color: Colors.purple,
                  onTap: () => _showCustomLimitDialog(),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _buildActionCard(
                  context,
                  title: 'Restore Default',
                  description: 'Restore the default 15 request limit',
                  icon: Icons.restore,
                  color: Colors.red,
                  onTap: () => _showPasswordDialog('Restore Default', () async {
                    final quotaProvider = context.read<AiQuotaProvider>();
                    return await quotaProvider.service.restoreDefaultLimit();
                  }),
                ),
              ] else ...[
                CustomCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.lock_open,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        'Authorization Required',
                        style: AppTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        'Enable authorization to access quota management controls',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
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
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey,
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