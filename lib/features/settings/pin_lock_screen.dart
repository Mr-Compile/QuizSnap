import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/security_provider.dart';
import '../../core/navigation/app_routes.dart';
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
  Timer? _blackScreenGuard;

  @override
  void dispose() {
    _blackScreenGuard?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  /// Navigates to the route the user was on before the app was locked,
  /// falling back to [AppRoutes.home] if no route was saved or the saved
  /// route is the pin-lock route itself.
  void _restoreRoute() {
    final securityProvider = context.read<SecurityProvider>();
    final savedRoute = securityProvider.consumeRouteBeforeLock();

    String destination;
    if (savedRoute != null &&
        savedRoute != AppRoutes.pinLock &&
        savedRoute != AppRoutes.setPin) {
      destination = savedRoute;
      debugPrint('[PinLockScreen] restoring saved route: $destination');
    } else {
      destination = AppRoutes.home;
      debugPrint('[PinLockScreen] no saved route, falling back to home');
    }

    // Use go() for a clean replacement — the pin-lock route was reached
    // via redirect (replacement), so there is nothing to pop back to.
    context.go(destination);
    debugPrint('[PinLockScreen] route restored to $destination');

    // Black-screen guard: if the navigation didn't reach a valid screen
    // within 1 second, force-navigate to home as a last resort.
    _blackScreenGuard?.cancel();
    _blackScreenGuard = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      final currentLocation = GoRouterState.of(context).uri.path;
      debugPrint('[PinLockScreen] black-screen guard check — current: $currentLocation');
      if (currentLocation == AppRoutes.pinLock) {
        debugPrint('[PinLockScreen] black-screen guard — forcing navigation to home');
        context.go(AppRoutes.home);
      }
    });
  }

  Future<void> _unlock() async {
    if (!_formKey.currentState!.validate()) return;

    final securityProvider = context.read<SecurityProvider>();
    final pin = _pinController.text;

    debugPrint('[PinLockScreen] unlock started');

    bool success = false;
    try {
      success = await securityProvider.verifyPin(pin);
    } catch (e) {
      debugPrint('[PinLockScreen] unlock error: $e');
      success = false;
    } finally {
      // Always clear the loading flag — verifyPin already does this
      // internally, but this is a defensive guarantee so no spinner
      // can remain active after unlock success or failure.
      if (securityProvider.isLoading) {
        securityProvider.clearLoading();
      }
    }

    if (!mounted) return;

    if (success) {
      debugPrint('[PinLockScreen] unlock success — restoring route');
      setState(() {
        _failedAttempts = 0;
      });
      _restoreRoute();
    } else {
      debugPrint('[PinLockScreen] unlock failed — incorrect PIN');
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
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
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                            ),
                            child: securityProvider.isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
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
                          color: Theme.of(context).colorScheme.error,
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
