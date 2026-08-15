import 'package:flutter/foundation.dart';
import '../services/secure_storage_service.dart';

class SecurityProvider with ChangeNotifier {
  final SecureStorageService _secureStorage;

  bool _isPinEnabled = false;
  bool _isAppLocked = false;
  bool _isSessionLocked = false;
  bool _isUnlocking = false;
  bool _isLoading = false;
  bool _lockScreenVisible = false;
  bool _isInitialized = false;
  DateTime? _lastUnlockTime;
  DateTime? _lastActivityTime;
  String? _errorMessage;

  // Brute-force protection state
  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;
  bool _isInLockout = false;

  /// Maximum failed PIN attempts before lockout.
  static const int maxFailedAttempts = 5;

  /// Lockout duration after exceeding max failed attempts.
  static const Duration lockoutDuration = Duration(seconds: 30);

  /// Grace period after unlock during which lifecycle-triggered
  /// lock requests are ignored (prevents relock loop).
  static const _unlockGracePeriod = Duration(seconds: 3);

  /// The route location the user was on before the app was locked.
  /// Used to restore the previous screen after successful unlock.
  String? _routeBeforeLock;

  bool get isPinEnabled => _isPinEnabled;
  bool get isAppLocked => _isAppLocked;
  bool get isSessionLocked => _isSessionLocked;
  bool get isLocked => _isAppLocked || _isSessionLocked;
  bool get isUnlocking => _isUnlocking;
  bool get isLoading => _isLoading;
  bool get lockScreenVisible => _lockScreenVisible;
  bool get isInitialized => _isInitialized;
  DateTime? get lastUnlockTime => _lastUnlockTime;
  DateTime? get lastActivityTime => _lastActivityTime;
  String? get errorMessage => _errorMessage;
  String? get routeBeforeLock => _routeBeforeLock;

  // Brute-force protection getters
  int get failedAttempts => _failedAttempts;
  DateTime? get lockoutEndTime => _lockoutEndTime;
  bool get isInLockout => _isInLockout && _lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!);

  /// Remaining seconds in the lockout (0 if not locked or expired).
  int get lockoutRemainingSeconds {
    if (!isInLockout || _lockoutEndTime == null) return 0;
    final remaining = _lockoutEndTime!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Returns true if we are within the unlock grace period.
  bool get _isInUnlockGracePeriod {
    if (_lastUnlockTime == null) return false;
    return DateTime.now().difference(_lastUnlockTime!) < _unlockGracePeriod;
  }

  SecurityProvider() : _secureStorage = SecureStorageService();

  /// Stores the route the user was on before locking so it can be
  /// restored after unlock. Only saves if not already on the pin-lock
  /// route and if no route has been saved yet (prevents overwriting).
  void setRouteBeforeLock(String route) {
    if (route == '/settings/pin-lock') return;
    if (_routeBeforeLock != null) return;
    _routeBeforeLock = route;
    debugPrint('[SecurityProvider] routeBeforeLock saved: $route');
  }

  /// Returns the saved route and clears it. Returns null if no route
  /// was saved.
  String? consumeRouteBeforeLock() {
    final route = _routeBeforeLock;
    _routeBeforeLock = null;
    return route;
  }

  // Initialize security settings
  Future<void> initialize() async {
    // Idempotent: if already initialized, don't re-read storage and
    // don't re-lock.  This prevents MainScreen.initState() from
    // re-locking the app after the user has already unlocked.
    if (_isInitialized) {
      debugPrint('[SecurityProvider] initialize() skipped — already initialized');
      return;
    }

    debugPrint('[SecurityProvider] initialize() started');
    _isLoading = true;
    notifyListeners();

    try {
      _isPinEnabled = await _secureStorage.isPinEnabled();
      _isAppLocked = _isPinEnabled;
      _lastActivityTime = DateTime.now();

      // Load persisted brute-force protection state so lockout survives
      // app pause/resume during the countdown.
      _failedAttempts = await _secureStorage.getPinFailedAttempts();
      _lockoutEndTime = await _secureStorage.getPinLockoutEndTime();
      _isInLockout = _lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!);
      // If the lockout has already expired, clear the stale state.
      if (_lockoutEndTime != null && !_isInLockout) {
        await _secureStorage.clearPinLockout();
        _failedAttempts = 0;
        _lockoutEndTime = null;
      }

      _isLoading = false;
      _isInitialized = true;
      debugPrint('[SecurityProvider] initialize() done — pinEnabled: $_isPinEnabled, appLocked: $_isAppLocked, failedAttempts: $_failedAttempts, inLockout: $_isInLockout');
      notifyListeners();
    } catch (e) {
      debugPrint('[SecurityProvider] initialize() error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // PIN Management
  Future<bool> setPin(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_isValidPinLength(pin)) {
        _errorMessage = 'Your PIN must contain 4–6 digits.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _secureStorage.storePin(pin);
      await _secureStorage.setPinEnabled(true);
      _isPinEnabled = true;
      // Do NOT lock the app here — setting a PIN enables protection
      // for future locks (Lock Now, app resume, session timeout).
      // Locking immediately caused a conflict with the success dialog
      // and prevented the user from seeing the "Enabled" state on the
      // Security screen.
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Validates that [pin] is 4–6 numeric digits.
  bool _isValidPinLength(String pin) {
    return pin.length >= 4 && pin.length <= 6 && RegExp(r'^[0-9]+$').hasMatch(pin);
  }

  Future<bool> verifyPin(String pin) async {
    debugPrint('[SecurityProvider] verifyPin() started');

    // Block all PIN verification during lockout — even the correct PIN
    // must not unlock the app while the countdown is active.
    if (isInLockout) {
      debugPrint('[SecurityProvider] verifyPin() blocked — in lockout (${lockoutRemainingSeconds}s remaining)');
      _errorMessage = 'Too many attempts. Try again in ${lockoutRemainingSeconds}s.';
      notifyListeners();
      return false;
    }

    _isUnlocking = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isValid = await _secureStorage.verifyPin(pin);

      if (isValid) {
        debugPrint('[SecurityProvider] verifyPin() success — unlocking');
        // Atomic unlock transaction:
        // 1. Clear both lock flags
        // 2. Record lastUnlockTime (for grace period)
        // 3. Record lastActivityTime (reset inactivity)
        // 4. Reset failed attempts + clear lockout
        // 5. Notify listeners so GoRouter redirect re-evaluates
        _isAppLocked = false;
        _isSessionLocked = false;
        _lastUnlockTime = DateTime.now();
        _lastActivityTime = DateTime.now();
        _failedAttempts = 0;
        _isInLockout = false;
        _lockoutEndTime = null;
        await _secureStorage.clearPinLockout();
        _isLoading = false;
        _isUnlocking = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('[SecurityProvider] verifyPin() failed — incorrect PIN');
        _errorMessage = 'Incorrect PIN';
        _isLoading = false;
        _isUnlocking = false;
        // Record the failed attempt for brute-force protection.
        await recordFailedAttempt();
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[SecurityProvider] verifyPin() error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      _isUnlocking = false;
      notifyListeners();
      return false;
    }
  }

  /// Records a failed PIN attempt and triggers lockout if the threshold
  /// (5 attempts) is reached. Persists state so it survives app restart.
  Future<void> recordFailedAttempt() async {
    _failedAttempts++;
    debugPrint('[SecurityProvider] failed attempt #$_failedAttempts');

    if (_failedAttempts >= maxFailedAttempts) {
      _lockoutEndTime = DateTime.now().add(lockoutDuration);
      _isInLockout = true;
      debugPrint('[SecurityProvider] lockout triggered until $_lockoutEndTime');
      await _secureStorage.setPinFailedAttempts(_failedAttempts);
      await _secureStorage.setPinLockoutEndTime(_lockoutEndTime);
    } else {
      await _secureStorage.setPinFailedAttempts(_failedAttempts);
    }
  }

  /// Clears the lockout state (called when the countdown expires or on
  /// successful unlock). Does NOT reset failed attempts — those are only
  /// reset on a successful unlock.
  Future<void> clearLockout() async {
    _isInLockout = false;
    _lockoutEndTime = null;
    await _secureStorage.setPinLockoutEndTime(null);
    notifyListeners();
  }

  /// Resets failed attempts to zero (called on successful unlock).
  Future<void> resetFailedAttempts() async {
    _failedAttempts = 0;
    _isInLockout = false;
    _lockoutEndTime = null;
    await _secureStorage.clearPinLockout();
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Verify old PIN first
      final isValid = await _secureStorage.verifyPin(oldPin);
      if (!isValid) {
        _errorMessage = 'Incorrect current PIN';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Set new PIN
      if (!_isValidPinLength(newPin)) {
        _errorMessage = 'Your PIN must contain 4–6 digits.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _secureStorage.storePin(newPin);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> disablePin() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _secureStorage.clearPin();
      await _secureStorage.setPinEnabled(false);
      await _secureStorage.clearPinLockout();
      _isPinEnabled = false;
      _isAppLocked = false;
      _isSessionLocked = false;
      _isInitialized = true;
      _failedAttempts = 0;
      _isInLockout = false;
      _lockoutEndTime = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lock Management
  void lockApp() {
    // Guard: don't lock if PIN is not enabled
    if (!_isPinEnabled) {
      debugPrint('[SecurityProvider] lockApp() ignored — PIN not enabled');
      return;
    }

    // Guard: don't lock if already locked
    if (isLocked) {
      debugPrint('[SecurityProvider] lockApp() ignored — already locked');
      return;
    }

    // Guard: don't lock during unlock transaction
    if (_isUnlocking) {
      debugPrint('[SecurityProvider] lockApp() ignored — unlock in progress');
      return;
    }

    // Guard: don't lock during grace period after unlock
    if (_isInUnlockGracePeriod) {
      debugPrint('[SecurityProvider] lockApp() ignored — within unlock grace period');
      return;
    }

    // Guard: don't lock if lock screen is already visible
    if (_lockScreenVisible) {
      debugPrint('[SecurityProvider] lockApp() ignored — lock screen already visible');
      return;
    }

    debugPrint('[SecurityProvider] lockApp() triggered');
    _isAppLocked = true;
    notifyListeners();
  }

  /// Lock the app due to session inactivity timeout.
  /// This is separate from [lockApp] so the two systems never conflict.
  void lockSession() {
    // Guard: don't lock if PIN is not enabled
    if (!_isPinEnabled) {
      debugPrint('[SecurityProvider] lockSession() ignored — PIN not enabled');
      return;
    }

    // Guard: don't lock if already locked
    if (isLocked) {
      debugPrint('[SecurityProvider] lockSession() ignored — already locked');
      return;
    }

    // Guard: don't lock during unlock transaction
    if (_isUnlocking) {
      debugPrint('[SecurityProvider] lockSession() ignored — unlock in progress');
      return;
    }

    // Guard: don't lock if lock screen is already visible
    if (_lockScreenVisible) {
      debugPrint('[SecurityProvider] lockSession() ignored — lock screen already visible');
      return;
    }

    debugPrint('[SecurityProvider] lockSession() triggered');
    _isSessionLocked = true;
    notifyListeners();
  }

  /// Record user activity — resets the inactivity clock.
  void recordActivity() {
    _lastActivityTime = DateTime.now();
  }

  Future<bool> attemptUnlock(String pin) async {
    return await verifyPin(pin);
  }

  // Error Management
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Defensive method to clear the loading flag.  Called from the
  /// [PinLockScreen] unlock finally-block as a guarantee that no
  /// spinner remains active after unlock.
  void clearLoading() {
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tracks whether the PIN lock screen is currently visible.
  /// Used by [lockApp] to prevent stacking duplicate lock screens.
  void setLockScreenVisible(bool visible) {
    _lockScreenVisible = visible;
    debugPrint('[SecurityProvider] lockScreenVisible = $visible');
  }

  // Clear all security data
  Future<void> clearAllSecurityData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _secureStorage.clearAllSecurityData();
      _isPinEnabled = false;
      _isAppLocked = false;
      _isSessionLocked = false;
      _isInitialized = true;
      _failedAttempts = 0;
      _isInLockout = false;
      _lockoutEndTime = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
