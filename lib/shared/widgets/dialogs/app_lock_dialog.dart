import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/security_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../pin_keypad.dart';

/// Modal dialog overlay that protects the app when it is locked.
///
/// This replaces the previous full-screen [PinLockScreen] route so the
/// underlying application remains visually intact but inaccessible
/// until the user enters the correct PIN.
///
/// Features:
/// * Material 3 design with lock icon, title, and PIN keypad.
/// * Uses the configured PIN length (4, 5, or 6) — not a hardcoded 6.
/// * Non-dismissible barrier (user cannot tap outside to dismiss).
/// * Inline error message on incorrect PIN (no raw exceptions).
/// * 30-second countdown after 5 failed attempts (brute-force protection).
/// * Theme-aware for light/dark mode.
/// * 48dp minimum tap targets via [PinKeypad].
class AppLockDialog extends StatefulWidget {
  const AppLockDialog({super.key});

  /// Shows the app lock dialog as a non-dismissible modal overlay.
  ///
  /// Returns `true` when the user successfully unlocks, or `false` if
  /// the dialog is dismissed without unlocking (should not happen under
  /// normal circumstances since the barrier is non-dismissible).
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => const AppLockDialog(),
    );
  }

  @override
  State<AppLockDialog> createState() => _AppLockDialogState();
}

class _AppLockDialogState extends State<AppLockDialog> {
  final _keypadKey = GlobalKey<PinKeypadState>();
  String? _errorText;
  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Check if we're starting in a lockout state (e.g. after app restart
    // during countdown).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    _countdownTimer?.cancel();
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

    // Validate against the configured PIN length.
    final requiredLength = securityProvider.pinLength;
    if (pin.length != requiredLength) {
      setState(() => _errorText =
          'Your PIN must be $requiredLength digits.');
      return;
    }

    bool success = false;
    try {
      success = await securityProvider.verifyPin(pin);
    } catch (e) {
      debugPrint('[AppLockDialog] unlock error: $e');
      success = false;
    } finally {
      if (securityProvider.isLoading) {
        securityProvider.clearLoading();
      }
    }

    if (!mounted) return;

    if (success) {
      debugPrint('[AppLockDialog] unlock success');
      _countdownTimer?.cancel();
      Navigator.of(context).pop(true);
    } else {
      _keypadKey.currentState?.clear();
      HapticFeedback.mediumImpact();

      final message = securityProvider.errorMessage ?? 'Incorrect PIN. Please try again.';
      setState(() => _errorText = message);

      // Check if the failed attempt triggered a lockout.
      if (securityProvider.isInLockout) {
        _startCountdown(securityProvider.lockoutRemainingSeconds);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final securityProvider = context.watch<SecurityProvider>();
    final inLockout = securityProvider.isInLockout || _countdownSeconds > 0;
    final pinLength = securityProvider.pinLength;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
        ),
        elevation: 0,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing6,
          vertical: AppTheme.spacing6,
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing4,
          vertical: AppTheme.spacing8,
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lockout card (shown only during lockout)
                if (inLockout) ...[
                  _buildLockoutCard(colorScheme),
                  const SizedBox(height: AppTheme.spacing6),
                ],

                // Lock icon (hidden during lockout)
                if (!inLockout) ...[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.bambooGreen600
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 32,
                      color: AppTheme.bambooGreen600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                ],

                // Title
                Text(
                  'App Locked',
                  style: AppTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing2),

                // Description
                Text(
                  inLockout
                      ? 'PIN entry is temporarily disabled.'
                      : 'Enter your PIN to continue.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppTheme.spacing6),

                // PIN keypad — uses the configured PIN length so a
                // 4-digit PIN shows 4 dots and auto-submits at 4.
                PinKeypad(
                  key: _keypadKey,
                  maxLength: pinLength,
                  minLength: pinLength,
                  dotCount: pinLength,
                  autoSubmit: true,
                  errorText: _errorText,
                  enabled: !inLockout && !securityProvider.isLoading,
                  onChanged: _onPinChanged,
                  onSubmit: _onPinSubmitted,
                ),

                const SizedBox(height: AppTheme.spacing4),

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
                  const SizedBox(height: AppTheme.spacing2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockoutCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing4),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_clock,
            size: 40,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(height: AppTheme.spacing3),
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
            style: AppTheme.bodySmall.copyWith(
              color: colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing3),
          Text(
            'Try again in',
            style: AppTheme.bodySmall.copyWith(
              color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing1),
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
          const SizedBox(height: AppTheme.spacing3),
          LinearProgressIndicator(
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
        ],
      ),
    );
  }
}
