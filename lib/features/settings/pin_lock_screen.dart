import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/security_provider.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/pin_keypad.dart';

/// Modern full-screen PIN lock screen.
///
/// The screen prevents interaction with the underlying app while the
/// app is locked. It shows a numeric keypad, PIN dot indicators, and a
/// live 30-second countdown after 5 failed attempts.
class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _keypadKey = GlobalKey<PinKeypadState>();
  String? _errorText;
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
    try {
      context.read<SecurityProvider>().setLockScreenVisible(false);
      debugPrint('[PinLockScreen] lock screen dismissed');
    } catch (_) {
      // Provider may be unavailable during app teardown.
    }
    super.dispose();
  }

  void _onPinChanged(String pin) {
    if (_errorText != null && mounted) {
      setState(() => _errorText = null);
    }
  }

  Future<void> _onPinSubmitted(String pin) async {
    final securityProvider = context.read<SecurityProvider>();

    // Block unlock during lockout.
    if (securityProvider.isInLockout) {
      setState(() => _errorText =
          'Too many attempts. Try again in ${securityProvider.lockoutRemainingSeconds}s.');
      _keypadKey.currentState?.clear();
      HapticFeedback.heavyImpact();
      return;
    }

    if (pin.length < 4) {
      setState(() => _errorText = 'Your PIN must contain at least 4 digits.');
      return;
    }

    bool success = false;
    try {
      success = await securityProvider.verifyPin(pin);
    } catch (e) {
      debugPrint('[PinLockScreen] unlock error: $e');
      success = false;
    } finally {
      if (securityProvider.isLoading) {
        securityProvider.clearLoading();
      }
    }

    if (!mounted) return;

    if (success) {
      debugPrint('[PinLockScreen] unlock success — restoring route');
      _countdownTimer?.cancel();
      _restoreRoute();
    } else {
      _keypadKey.currentState?.clear();
      HapticFeedback.mediumImpact();

      final message = securityProvider.errorMessage ?? 'Incorrect PIN';
      setState(() => _errorText = message);

      // Check if the failed attempt triggered a lockout.
      if (securityProvider.isInLockout) {
        _startCountdown(securityProvider.lockoutRemainingSeconds);
      }
    }
  }

  /// Navigates to the route the user was on before the app was locked,
  /// falling back to [AppRoutes.home] if no route was saved.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final securityProvider = context.watch<SecurityProvider>();
    final inLockout = securityProvider.isInLockout || _countdownSeconds > 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.vertical,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing4,
                  vertical: AppTheme.spacing4,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lockout card
                    if (inLockout) ...[
                      _buildLockoutCard(colorScheme),
                      const SizedBox(height: AppTheme.spacing6),
                    ],

                    // Normal lock icon (hidden during lockout)
                    if (!inLockout) ...[
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.bambooGreen600
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 40,
                          color: AppTheme.bambooGreen600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                    ],

                    // Titles
                    Text(
                      'QuizSnap',
                      style: AppTheme.headlineSmall.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing1),
                    Text(
                      'App Locked',
                      style: AppTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing2),
                    Text(
                      inLockout
                          ? 'PIN entry is temporarily disabled.'
                          : 'Enter your PIN to continue.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppTheme.spacing8),

                    // PIN keypad
                    PinKeypad(
                      key: _keypadKey,
                      maxLength: 6,
                      minLength: 4,
                      autoSubmit: true,
                      errorText: _errorText,
                      enabled: !inLockout && !securityProvider.isLoading,
                      onChanged: _onPinChanged,
                      onSubmit: _onPinSubmitted,
                    ),

                    const SizedBox(height: AppTheme.spacing6),

                    // Failed attempts indicator
                    if (!inLockout && securityProvider.failedAttempts > 0)
                      Text(
                        'Incorrect PIN. ${securityProvider.failedAttempts} of ${SecurityProvider.maxFailedAttempts} failed attempts.',
                        style: AppTheme.bodySmall.copyWith(
                          color: colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else if (!inLockout)
                      const SizedBox(height: AppTheme.spacing4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockoutCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing6),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_clock,
            size: 48,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'Too many attempts',
            style: AppTheme.titleMedium.copyWith(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing2),
          Text(
            'For your protection, PIN entry is temporarily locked.',
            style: AppTheme.bodyMedium.copyWith(
              color: colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'Try again in',
            style: AppTheme.bodySmall.copyWith(
              color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing2),
          Text(
            _countdownSeconds.toString().padLeft(2, '0'),
            style: AppTheme.headlineLarge.copyWith(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing1),
          Text(
            'seconds',
            style: AppTheme.bodySmall.copyWith(
              color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing4),
          SizedBox(
            width: double.infinity,
            child: LinearProgressIndicator(
              value: 1.0 -
                  (_countdownSeconds /
                      SecurityProvider.lockoutDuration.inSeconds),
              backgroundColor:
                  colorScheme.onErrorContainer.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.onErrorContainer,
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
