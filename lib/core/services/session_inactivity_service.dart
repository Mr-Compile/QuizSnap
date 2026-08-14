import 'dart:async';
import 'package:flutter/foundation.dart';
import '../providers/security_provider.dart';
import '../providers/focus_mode_provider.dart';

/// Centralized timer configuration for session inactivity.
class SessionTimerConfig {
  SessionTimerConfig._();

  /// Total inactivity duration before the session locks.
  static const Duration sessionTimeout = Duration(seconds: 60);

  /// Inactivity duration before the warning dialog appears.
  static const Duration warningThreshold = Duration(seconds: 45);

  /// Countdown duration shown in the warning dialog (sessionTimeout - warningThreshold).
  static const Duration warningDuration = Duration(seconds: 15);
}

/// Tracks user inactivity and triggers a warning dialog + session lock.
///
/// This service is completely separate from the app PIN lock
/// ([SecurityProvider.lockApp]). It only fires when the app is in the
/// foreground and the user has not interacted for the configured duration.
///
/// States:
/// * **idle** — normal operation, timer ticking.
/// * **warning** — warning dialog should be visible, countdown running.
/// * **locked** — session has been locked via [SecurityProvider.lockSession].
class SessionInactivityService with ChangeNotifier {
  final SecurityProvider _securityProvider;
  FocusModeProvider? _focusModeProvider;

  Timer? _tickTimer;
  DateTime? _lastActivityTime;
  bool _isWarningPhase = false;
  bool _isPaused = false;
  int _countdown = 0;

  bool get isWarningPhase => _isWarningPhase;
  int get countdown => _countdown;
  bool get isPaused => _isPaused;
  bool get isFocusMode => _focusModeProvider?.isFocusMode ?? false;

  SessionInactivityService(this._securityProvider);

  /// Attach a [FocusModeProvider] so the service can suspend itself
  /// during study/exam sessions.
  void attachFocusModeProvider(FocusModeProvider provider) {
    _focusModeProvider = provider;
    _focusModeProvider!.addListener(_onFocusModeChanged);
  }

  /// Start the inactivity tracking timer.
  void start() {
    if (_tickTimer != null) return;
    _lastActivityTime = DateTime.now();
    _isPaused = false;
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    debugPrint('[SessionInactivity] started');
  }

  /// Called when [FocusModeProvider] state changes.
  void _onFocusModeChanged() {
    if (isFocusMode) {
      // Entering focus mode — cancel any warning and pause counting.
      _cancelWarning();
      debugPrint('[SessionInactivity] focus mode active — suspending');
    } else {
      // Exiting focus mode — reset timer to full 60s.
      _lastActivityTime = DateTime.now();
      _cancelWarning();
      debugPrint('[SessionInactivity] focus mode ended — timer reset');
    }
  }

  /// Stop the inactivity tracking timer (e.g. when app goes to background).
  void stop() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _isPaused = true;
    _cancelWarning();
    debugPrint('[SessionInactivity] stopped');
  }

  /// Record real user activity — resets the inactivity clock.
  void recordActivity() {
    _lastActivityTime = DateTime.now();
    if (_isWarningPhase) {
      _cancelWarning();
    }
  }

  /// Immediately lock the session (used by "Lock Now" button).
  void lockNow() {
    _cancelWarning();
    _securityProvider.lockSession();
  }

  /// Dismiss the warning phase and reset.
  void dismissWarning() {
    _cancelWarning();
    recordActivity();
  }

  void _cancelWarning() {
    if (_isWarningPhase) {
      _isWarningPhase = false;
      _countdown = 0;
      notifyListeners();
    }
  }

  void _tick() {
    if (_isPaused) return;
    if (isFocusMode) return;
    if (!_securityProvider.isPinEnabled) return;
    if (_securityProvider.isLocked) return;
    if (_securityProvider.isUnlocking) return;
    if (_lastActivityTime == null) return;

    final elapsed = DateTime.now().difference(_lastActivityTime!);

    if (elapsed >= SessionTimerConfig.sessionTimeout) {
      // Session timeout reached — lock the session.
      _cancelWarning();
      _securityProvider.lockSession();
      return;
    }

    if (elapsed >= SessionTimerConfig.warningThreshold) {
      // Enter or continue warning phase.
      final newCountdown =
          SessionTimerConfig.sessionTimeout.inSeconds - elapsed.inSeconds;
      if (newCountdown <= 0) {
        _cancelWarning();
        _securityProvider.lockSession();
        return;
      }
      if (!_isWarningPhase || _countdown != newCountdown) {
        _isWarningPhase = true;
        _countdown = newCountdown;
        notifyListeners();
      }
    } else {
      // Still within active period — cancel warning if it was showing.
      if (_isWarningPhase) {
        _cancelWarning();
      }
    }
  }

  @override
  void dispose() {
    _focusModeProvider?.removeListener(_onFocusModeChanged);
    _tickTimer?.cancel();
    _tickTimer = null;
    super.dispose();
  }
}
