import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Storage keys
  static const String _groqApiKeyKey = 'groq_api_key';
  static const String _appPinKey = 'app_pin';
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _quotaAuthPasswordKey = 'quota_auth_password';
  static const String _quotaAuthEnabledKey = 'quota_auth_enabled';

  // Groq API Key Storage
  Future<void> storeGroqApiKey(String apiKey) async {
    await _storage.write(key: _groqApiKeyKey, value: apiKey);
  }

  Future<String?> getGroqApiKey() async {
    return await _storage.read(key: _groqApiKeyKey);
  }

  Future<void> clearGroqApiKey() async {
    await _storage.delete(key: _groqApiKeyKey);
  }

  Future<bool> hasGroqApiKey() async {
    final key = await _storage.read(key: _groqApiKeyKey);
    return key != null && key.isNotEmpty;
  }

  /// Get a masked version of the API key for display purposes
  Future<String?> getMaskedGroqApiKey() async {
    final key = await getGroqApiKey();
    if (key == null || key.isEmpty) return null;
    
    if (key.length <= 8) {
      return 'gsk_****';
    }
    
    return '${key.substring(0, 4)}****${key.substring(key.length - 4)}';
  }

  // PIN Storage (hashed)
  Future<void> storePin(String pin) async {
    final hashedPin = _hashPin(pin);
    await _storage.write(key: _appPinKey, value: hashedPin);
  }

  Future<String?> getPin() async {
    return await _storage.read(key: _appPinKey);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _appPinKey);
  }

  Future<bool> verifyPin(String inputPin) async {
    final storedPin = await getPin();
    if (storedPin == null) return false;
    
    final hashedInput = _hashPin(inputPin);
    return storedPin == hashedInput;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // PIN Enabled State
  Future<void> setPinEnabled(bool enabled) async {
    await _storage.write(key: _pinEnabledKey, value: enabled.toString());
  }

  Future<bool> isPinEnabled() async {
    final value = await _storage.read(key: _pinEnabledKey);
    return value == 'true';
  }

  // Biometric Enabled State
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  // Clear all security data
  Future<void> clearAllSecurityData() async {
    await clearGroqApiKey();
    await clearPin();
    await setPinEnabled(false);
    await setBiometricEnabled(false);
    await clearQuotaAuthPassword();
    await setQuotaAuthEnabled(false);
  }

  // Quota Authorization Password Storage (hashed)
  Future<void> storeQuotaAuthPassword(String password) async {
    final hashedPassword = _hashPin(password); // Reuse the same hashing method
    await _storage.write(key: _quotaAuthPasswordKey, value: hashedPassword);
  }

  Future<String?> getQuotaAuthPassword() async {
    return await _storage.read(key: _quotaAuthPasswordKey);
  }

  Future<void> clearQuotaAuthPassword() async {
    await _storage.delete(key: _quotaAuthPasswordKey);
  }

  Future<bool> verifyQuotaAuthPassword(String inputPassword) async {
    final storedPassword = await getQuotaAuthPassword();
    if (storedPassword == null) return false;
    
    final hashedInput = _hashPin(inputPassword);
    return storedPassword == hashedInput;
  }

  Future<bool> hasQuotaAuthPassword() async {
    final password = await _storage.read(key: _quotaAuthPasswordKey);
    return password != null && password.isNotEmpty;
  }

  // Quota Authorization Enabled State
  Future<void> setQuotaAuthEnabled(bool enabled) async {
    await _storage.write(key: _quotaAuthEnabledKey, value: enabled.toString());
  }

  Future<bool> isQuotaAuthEnabled() async {
    final value = await _storage.read(key: _quotaAuthEnabledKey);
    return value == 'true';
  }
}
