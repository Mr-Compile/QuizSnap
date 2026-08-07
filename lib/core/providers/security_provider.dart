import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../services/secure_storage_service.dart';

class SecurityProvider with ChangeNotifier {
  final SecureStorageService _secureStorage = SecureStorageService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isPinEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isLocked = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isPinEnabled => _isPinEnabled;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isLocked => _isLocked;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize security settings
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isPinEnabled = await _secureStorage.isPinEnabled();
      _isBiometricEnabled = await _secureStorage.isBiometricEnabled();
      _isLocked = _isPinEnabled;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isValid = await _secureStorage.verifyPin(pin);
      
      if (isValid) {
        _isLocked = false;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Incorrect PIN';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
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

  // Biometric Authentication
  Future<bool> canCheckBiometrics() async {
    return await _localAuth.canCheckBiometrics;
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access QuizSnap',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (enabled) {
        // Check if biometrics are available
        final canCheck = await canCheckBiometrics();
        if (!canCheck) {
          _errorMessage = 'No biometrics available on this device';
          _isLoading = false;
          notifyListeners();
          return;
        }

        // Test authentication
        final authenticated = await authenticateWithBiometrics();
        if (!authenticated) {
          _errorMessage = 'Biometric authentication failed';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      await _secureStorage.setBiometricEnabled(enabled);
      _isBiometricEnabled = enabled;
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
      _isLocked = true;
      notifyListeners();
    }
  }

  Future<bool> attemptUnlock(String pin) async {
    return await verifyPin(pin);
  }

  Future<bool> attemptBiometricUnlock() async {
    if (!_isBiometricEnabled) return false;
    
    final authenticated = await authenticateWithBiometrics();
    if (authenticated) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Error Management
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all security data
  Future<void> clearAllSecurityData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _secureStorage.clearAllSecurityData();
      _isPinEnabled = false;
      _isBiometricEnabled = false;
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
