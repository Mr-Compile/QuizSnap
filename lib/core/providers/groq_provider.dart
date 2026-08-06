import 'package:flutter/foundation.dart';
import '../services/groq_service.dart';
import '../services/secure_storage_service.dart';

class GroqProvider with ChangeNotifier {
  final GroqService _groqService = GroqService();
  final SecureStorageService _secureStorage = SecureStorageService();
  
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  GroqService get service => _groqService;

  Future<bool> initialize(String apiKey) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _groqService.initialize(apiKey);
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> initializeFromSecureStorage() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _groqService.initializeFromSecureStorage();
      _isInitialized = _groqService.isInitialized;
      _isLoading = false;
      notifyListeners();
      return _isInitialized;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> testConnection(String apiKey) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create a temporary client to test the connection
      final testService = GroqService();
      await testService.initialize(apiKey);
      
      // Try a simple request to verify the connection
      await testService.summarizeContent(content: 'Test', maxLength: 10);
      
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

  void clearApiKey() {
    _groqService.clearApiKey();
    _secureStorage.clearGroqApiKey();
    _isInitialized = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}