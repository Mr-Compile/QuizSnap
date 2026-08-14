import 'package:flutter/foundation.dart';
import '../services/secure_storage_service.dart';

class SecurityProvider with ChangeNotifier {
  final SecureStorageService _secureStorage;

  bool _isPinEnabled = false;
  bool _isLocked = false;
  bool _isLoading = false;
  String? _errorMessage;

  /// The route location the user was on before the app was locked.
  /// Used to restore the previous screen after successful unlock.
  String? _routeBeforeLock;

  bool get isPinEnabled => _isPinEnabled;
  bool get isLocked => _isLocked;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get routeBeforeLock => _routeBeforeLock;

  SecurityProvider() : _secureStorage = SecureStorageService();

  /// Stores the route the user was on before locking so it can be
  /// restored after unlock. Only saves if not already on the pin-lock
  /// route and if no route has been saved yet (prevents overwriting).
  void setRouteBeforeLock(String route) {
    if (route == '/settings/pin-lock') return;
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
    debugPrint('[SecurityProvider] initialize() started');
    _isLoading = true;
    notifyListeners();

    try {
      _isPinEnabled = await _secureStorage.isPinEnabled();
      _isLocked = _isPinEnabled;
      _isLoading = false;
      debugPrint('[SecurityProvider] initialize() done — pinEnabled: $_isPinEnabled, locked: $_isLocked');
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
      if (pin.length != 4) {
        _errorMessage = 'PIN must be 4 digits';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _secureStorage.storePin(pin);
      await _secureStorage.setPinEnabled(true);
      _isPinEnabled = true;
      _isLocked = true;
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

  Future<bool> verifyPin(String pin) async {
    debugPrint('[SecurityProvider] verifyPin() started');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isValid = await _secureStorage.verifyPin(pin);

      if (isValid) {
        debugPrint('[SecurityProvider] verifyPin() success — unlocking');
        _isLocked = false;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('[SecurityProvider] verifyPin() failed — incorrect PIN');
        _errorMessage = 'Incorrect PIN';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[SecurityProvider] verifyPin() error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
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
      if (newPin.length != 4) {
        _errorMessage = 'PIN must be 4 digits';
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
      _isPinEnabled = false;
      _isLocked = false;
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
    if (_isPinEnabled) {
      debugPrint('[SecurityProvider] lockApp() triggered');
      _isLocked = true;
      notifyListeners();
    }
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

  // Clear all security data
  Future<void> clearAllSecurityData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _secureStorage.clearAllSecurityData();
      _isPinEnabled = false;
      _isLocked = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
