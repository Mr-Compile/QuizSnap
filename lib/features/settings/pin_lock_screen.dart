import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/security_provider.dart';
import '../../core/theme/app_theme.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePin = true;
  int _failedAttempts = 0;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (!_formKey.currentState!.validate()) return;

    final securityProvider = context.read<SecurityProvider>();
    final pin = _pinController.text;

    final success = await securityProvider.verifyPin(pin);

    if (!mounted) return;

    if (success) {
      setState(() {
        _failedAttempts = 0;
      });
      Navigator.pop(context);
    } else {
      setState(() {
        _failedAttempts++;
      });
      _pinController.clear();
      
      if (_failedAttempts >= 3) {
        _showTooManyAttemptsDialog();
      }
    }
  }

  void _showTooManyAttemptsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Too Many Failed Attempts'),
        content: const Text('You have made too many incorrect attempts. Please try again later.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _failedAttempts = 0;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SecurityProvider>(
        builder: (context, securityProvider, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    size: 80,
                    color: AppTheme.bambooGreen600,
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                  Text(
                    'QuizSnap is Locked',
                    style: AppTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Enter your PIN to unlock',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _pinController,
                          obscureText: _obscurePin,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••',
                            hintStyle: TextStyle(
                              fontSize: 32,
                              letterSpacing: 8,
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePin ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePin = !_obscurePin;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your PIN';
                            }
                            if (value.length != 4) {
                              return 'PIN must be 4 digits';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _unlock(),
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: securityProvider.isLoading ? null : _unlock,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.bambooGreen600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                            ),
                            child: securityProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Unlock',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  if (_failedAttempts > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spacingLg),
                      child: Text(
                        'Incorrect PIN. $_failedAttempts failed attempt${_failedAttempts > 1 ? 's' : ''}.',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
