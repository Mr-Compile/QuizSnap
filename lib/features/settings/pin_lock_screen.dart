import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Timer? _blackScreenGuard;
  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Track that the lock screen is visible so lockApp() can guard
    // against stacking duplicate lock screens.
    context.read<SecurityProvider>().setLockScreenVisible(true);
    debugPrint('[PinLockScreen] lock screen shown');

    // Check if we're starting in a lockout state (e.g. after app restart
    // during countdown).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLockoutState();
    });
  }

  void _checkLockoutState() {
    final securityProvider = context.read<SecurityProvider>();
    if (securityProvider.isInLockout) {
      _startCountdown(securityProvider.lockoutRemainingSeconds);
    }
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = seconds;
    });

    // Haptic feedback when lockout begins.
    HapticFeedback.heavyImpact();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdownSeconds--;
      });

      if (_countdownSeconds <= 0) {
        timer.cancel();
        _onLockoutExpired();
      }
    });
  }

  void _onLockoutExpired() {
    final securityProvider = context.read<SecurityProvider>();
    // Clear the lockout but keep failed attempts count — the user still
    // needs to enter the correct PIN to reset attempts to 0.
    securityProvider.clearLockout();
    // Light haptic to signal re-enabled input.
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() {
        _countdownSeconds = 0;
      });
    }
  }

  @override
  void dispose() {
    _blackScreenGuard?.cancel();
    _countdownTimer?.cancel();
    // Mark the lock screen as no longer visible.
    // Use read() since the provider may still be available at dispose time.
    try {
      context.read<SecurityProvider>().setLockScreenVisible(false);
      debugPrint('[PinLockScreen] lock screen dismissed');
    } catch (_) {
      // Provider may be unavailable during app teardown.
    }
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
    // Block unlock attempts during lockout — even the correct PIN is
    // rejected while the countdown is active.
    final securityProvider = context.read<SecurityProvider>();
    if (securityProvider.isInLockout) {
      HapticFeedback.heavyImpact();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final pin = _pinController.text;

    debugPrint('[PinLockScreen] unlock started');

    bool success = false;
    try {
      // verifyPin() implements the atomic unlock transaction:
      //   1. sets isUnlocking = true
      //   2. validates PIN
      //   3. sets isLocked = false + lastUnlockTime = now
      //   4. resets failed attempts + clears lockout
      //   5. notifies listeners
      //   6. sets isUnlocking = false
      // It also records failed attempts and triggers lockout internally.
      success = await securityProvider.verifyPin(pin);
    } catch (e) {
      debugPrint('[PinLockScreen] unlock error: $e');
      success = false;
    } finally {
      // Defensive: always clear loading + unlocking flags so no
      // spinner or lock state can remain stuck.
      if (securityProvider.isLoading) {
        securityProvider.clearLoading();
      }
    }

    if (!mounted) return;

    if (success) {
      debugPrint('[PinLockScreen] unlock success — '
          'appLocked=${securityProvider.isAppLocked}, '
          'sessionLocked=${securityProvider.isSessionLocked}, '
          'restoring route');
      _countdownTimer?.cancel();
      // isLocked is already false (set by verifyPin), so we can
      // safely navigate away from the lock screen.
      _restoreRoute();
    } else {
      debugPrint('[PinLockScreen] unlock failed — incorrect PIN');
      _pinController.clear();

      // Error haptic feedback on wrong PIN.
      HapticFeedback.mediumImpact();

      // Check if the failed attempt triggered a lockout.
      if (securityProvider.isInLockout) {
        _startCountdown(securityProvider.lockoutRemainingSeconds);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SecurityProvider>(
        builder: (context, securityProvider, child) {
          final inLockout = securityProvider.isInLockout || _countdownSeconds > 0;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lockout card (shown when in lockout).
                  if (inLockout) ...[
                    _buildLockoutCard(),
                    const SizedBox(height: AppTheme.spacingXl),
                  ],
                  // Normal lock icon (hidden during lockout to avoid clutter).
                  if (!inLockout)
                    Icon(
                      Icons.lock,
                      size: 80,
                      color: AppTheme.bambooGreen600,
                    ),
                  if (!inLockout) const SizedBox(height: AppTheme.spacingXl),
                  Text(
                    'QuizSnap is Locked',
                    style: AppTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    inLockout
                        ? 'Input temporarily disabled'
                        : 'Enter your PIN to unlock',
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
                          enabled: !inLockout,
                          style: TextStyle(
                            fontSize: 32,
                            letterSpacing: 8,
                            color: inLockout
                                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                                : null,
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
                              onPressed: inLockout
                                  ? null
                                  : () {
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
                            onPressed: (inLockout || securityProvider.isLoading)
                                ? null
                                : _unlock,
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
                  // Failed attempts indicator (only when not in lockout).
                  if (!inLockout && securityProvider.failedAttempts > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spacingLg),
                      child: Text(
                        'Incorrect PIN. ${securityProvider.failedAttempts} of ${SecurityProvider.maxFailedAttempts} failed attempts.',
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

  // ─────────────────────────────────────────────────────────────────────
  //  Lockout card (Phase 3-4 — brute-force protection UI)
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildLockoutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_clock,
            size: 48,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'Too many attempts',
            style: AppTheme.titleMedium.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing2),
          Text(
            'For your security, PIN input is temporarily disabled.',
            style: AppTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing4),
          // Live countdown text.
          Text(
            'Try again in ${_countdownSeconds}s',
            style: AppTheme.headlineSmall.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacing3),
          // Subtle progress indicator.
          SizedBox(
            width: double.infinity,
            child: LinearProgressIndicator(
              value: 1.0 - (_countdownSeconds / SecurityProvider.lockoutDuration.inSeconds),
              backgroundColor: Theme.of(context).colorScheme.onErrorContainer.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onErrorContainer,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
