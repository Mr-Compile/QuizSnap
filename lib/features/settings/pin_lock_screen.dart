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
/// app is locked. It shows a numeric keypad, PIN dot indicators, and
/// inline error feedback on incorrect PINs.
///
/// When [isOverlay] is true (default), the widget is rendered as a
/// full-screen overlay on top of the application content by
/// [_AppLockHandler] in main.dart.  On successful unlock it simply
/// clears the lock state via [SecurityProvider.verifyPin] — the
/// overlay then disappears because the Consumer rebuilds with
/// `isLocked == false`.  No route navigation is performed.
///
/// When [isOverlay] is false, the widget behaves as a standalone route
/// (legacy behaviour used by the `/settings/pin-lock` route) and
/// restores the previous route on unlock.
///
/// When the brute-force cooldown is active (5 failed attempts), a
/// centered [CooldownModalOverlay] is rendered INSIDE this screen's
/// own [Stack] — NOT via showDialog().  This keeps the PIN screen and
/// the cooldown panel in the same widget tree, eliminating the
/// Navigator/Overlay layering problems that occurred when the cooldown
/// was shown as a separate dialog.  The normal PIN layout remains
/// visible behind the dimmed barrier, and the keypad is disabled until
/// the countdown expires.
class PinLockScreen extends StatefulWidget {
  final bool isOverlay;

  const PinLockScreen({super.key, this.isOverlay = true});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _keypadKey = GlobalKey<PinKeypadState>();
  String? _errorText;
  Timer? _blackScreenGuard;

  @override
  void initState() {
    super.initState();
    // Track that the lock screen is visible so lockApp() can guard
    // against stacking duplicate lock screens.  In overlay mode the
    // _AppLockHandler manages this flag, so we only set it in route
    // mode.
    if (!widget.isOverlay) {
      context.read<SecurityProvider>().setLockScreenVisible(true);
    }
    debugPrint('[PinLockScreen] lock screen shown (overlay=${widget.isOverlay})');
  }

  @override
  void dispose() {
    _blackScreenGuard?.cancel();
    // Only manage lockScreenVisible in route mode — in overlay mode the
    // _AppLockHandler owns this flag.
    if (!widget.isOverlay) {
      try {
        context.read<SecurityProvider>().setLockScreenVisible(false);
        debugPrint('[PinLockScreen] lock screen dismissed');
      } catch (_) {
        // Provider may be unavailable during app teardown.
      }
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

    // Block unlock during lockout — the cooldown overlay is already
    // visible and the keypad should be disabled, but this is a
    // defensive guard in case a submit event slips through.
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

    // Validate against the configured PIN length — a 4-digit PIN must
    // be unlockable with exactly 4 digits, not forced to 6.
    final requiredLength = securityProvider.pinLength;
    if (pin.length != requiredLength) {
      setState(() => _errorText = 'Your PIN must be $requiredLength digits.');
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
      debugPrint('[PinLockScreen] unlock success (overlay=${widget.isOverlay})');
      // In overlay mode, verifyPin() already cleared isLocked, which
      // causes the _AppLockHandler Consumer to rebuild and remove this
      // overlay.  No route navigation is needed — the user returns to
      // the exact screen they were on.
      if (!widget.isOverlay) {
        _restoreRoute();
      }
    } else {
      _keypadKey.currentState?.clear();
      HapticFeedback.mediumImpact();

      final message = securityProvider.errorMessage ?? 'Incorrect PIN';
      setState(() => _errorText = message);

      // If the failed attempt triggered a lockout, the
      // CooldownModalOverlay will appear automatically because the
      // build() method watches isInLockout — no showDialog() is needed.
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
    final inLockout = securityProvider.isInLockout;

    // In overlay mode the widget sits on top of the entire app inside
    // a Stack.  We use a fully opaque Scaffold so the underlying
    // application content is completely hidden and not interactable.
    //
    // The cooldown overlay is rendered INSIDE this widget's own Stack
    // (not via showDialog) so the PIN screen and cooldown panel belong
    // to the same widget tree — no third Navigator/Overlay layer.
    return PopScope(
      canPop: false,
      child: Scaffold(
        // Force an opaque background so nothing behind the lock is
        // visible, even during theme transitions.
        backgroundColor: colorScheme.surface,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Stack(
            children: [
              // ── PIN lock content ──────────────────────────────────
              SingleChildScrollView(
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
                        // Lock icon — always visible (the cooldown overlay
                        // appears on top of this, not as a replacement).
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

                        // Titles — always visible
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
                          'Enter your PIN to continue.',
                          style: AppTheme.bodyMedium.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: AppTheme.spacing8),

                        // PIN keypad — uses the configured PIN length so a
                        // 4-digit PIN shows 4 dots and auto-submits at 4.
                        // Disabled during cooldown; the overlay sits on top.
                        PinKeypad(
                          key: _keypadKey,
                          maxLength: securityProvider.pinLength,
                          minLength: securityProvider.pinLength,
                          dotCount: securityProvider.pinLength,
                          autoSubmit: true,
                          errorText: _errorText,
                          enabled: !inLockout && !securityProvider.isLoading,
                          onChanged: _onPinChanged,
                          onSubmit: _onPinSubmitted,
                        ),

                        const SizedBox(height: AppTheme.spacing6),

                        // Failed attempts indicator (only when not in
                        // lockout — the overlay handles the lockout message).
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

              // ── Cooldown overlay (same widget tree, no showDialog) ──
              // Rendered on top of the PIN content when the brute-force
              // lockout is active.  This is the ONLY cooldown UI layer.
              if (inLockout)
                CooldownModalOverlay(
                  securityProvider: securityProvider,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A centered modal overlay rendered INSIDE the [PinLockScreen]'s own
/// [Stack] when the brute-force cooldown is active.
///
/// This is NOT shown via showDialog() — it is a plain widget that
/// belongs to the same widget tree as the PIN screen.  This eliminates
/// the Navigator/Overlay layering problems that occurred when the
/// cooldown was a separate dialog.
///
/// The overlay displays:
/// * A modal barrier (dimmed background)
/// * A security/shield icon
/// * "Too many attempts" title
/// * An explanation message
/// * A live countdown ("Try again in N seconds")
/// * A linear progress indicator derived from the actual remaining
///   cooldown (computed from [SecurityProvider.lockoutEndTime], not
///   from an in-memory timer, so it survives widget rebuilds and app
///   lifecycle events)
/// * Supporting text
///
/// The overlay is non-dismissible (no "Got it" button) — it
/// auto-disappears when the countdown reaches zero because
/// [SecurityProvider.isInLockout] becomes false, which triggers a
/// rebuild of the parent [Stack] and removes this overlay.
///
/// The countdown display is driven by a 1-second [Timer.periodic] that
/// only updates the **display** — the authoritative remaining time is
/// always computed from `lockoutEndTime - DateTime.now()` so the
/// countdown cannot drift or reset due to rebuilds.
class CooldownModalOverlay extends StatefulWidget {
  final SecurityProvider securityProvider;

  const CooldownModalOverlay({
    super.key,
    required this.securityProvider,
  });

  @override
  State<CooldownModalOverlay> createState() => _CooldownModalOverlayState();
}

class _CooldownModalOverlayState extends State<CooldownModalOverlay> {
  Timer? _displayTimer;
  int _displaySeconds = 0;

  @override
  void initState() {
    super.initState();
    // Initialise the display from the authoritative source.
    _displaySeconds = widget.securityProvider.lockoutRemainingSeconds;
    _startDisplayTimer();
  }

  void _startDisplayTimer() {
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = widget.securityProvider.lockoutRemainingSeconds;

      setState(() {
        _displaySeconds = remaining;
      });

      if (remaining <= 0) {
        timer.cancel();
        // Clear the lockout state in the provider — this re-enables
        // the keypad on the PIN screen behind us and causes the
        // parent Stack to rebuild without this overlay.
        widget.securityProvider.clearLockout();
      }
    });
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final totalDuration = SecurityProvider.lockoutDuration.inSeconds;
    final progress = totalDuration > 0
        ? (_displaySeconds / totalDuration).clamp(0.0, 1.0)
        : 0.0;

    return Positioned.fill(
      child: Semantics(
        label: 'Cooldown overlay: Too many attempts. '
            'Try again in $_displaySeconds seconds.',
        namesRoute: true,
        child: Material(
          // Modal barrier — dimmed background that blocks interaction
          // with the PIN keypad behind it.  Uses a semantic theme
          // color, not a hardcoded black/white.
          color: colorScheme.scrim.withValues(alpha: 0.6),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? AppTheme.spacing8 : AppTheme.spacing4,
                vertical: AppTheme.spacing8,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 420 : double.infinity,
                ),
                child: Container(
                  // Centered panel — uses surfaceContainer for a
                  // theme-aware elevated surface.
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppTheme.rounded2xl),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? AppTheme.spacing8 : AppTheme.spacing6,
                    vertical: AppTheme.spacing6,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Security icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer
                                .withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_clock,
                            size: 32,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),

                        // Title
                        Text(
                          'Too many attempts',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: isTablet ? AppTheme.text2xl : AppTheme.textLg,
                            fontWeight: AppTheme.fontSemiBold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacing3),

                        // Explanation
                        Text(
                          'For your protection, PIN entry is temporarily locked.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacing5),

                        // "Try again in" label
                        Text(
                          'Try again in',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacing2),

                        // Countdown — the strongest visual element
                        Text(
                          '$_displaySeconds',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacing1),
                        Text(
                          _displaySeconds == 1 ? 'second' : 'seconds',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: AppTheme.spacing5),

                        // Linear progress indicator — derived from the actual
                        // remaining cooldown (not faked).
                        Semantics(
                          label: 'Cooldown progress: ${(_displaySeconds / totalDuration * 100).round()} percent remaining',
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                colorScheme.errorContainer.withValues(alpha: 0.3),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(colorScheme.error),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacing4),

                        // Supporting text
                        Text(
                          'PIN entry will be available when the timer reaches zero.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
