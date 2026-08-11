import 'package:flutter/foundation.dart';
import '../services/groq_service.dart';
import '../services/secure_storage_service.dart';
import '../models/groq_models.dart';

class GroqProvider with ChangeNotifier {
  final GroqService _groqService = GroqService();
  final SecureStorageService _secureStorage;
  
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isAutoInitializing = false;
  String? _errorMessage;
  String? _selectedModel;
  bool _hasAttemptedAutoInit = false;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isAutoInitializing => _isAutoInitializing;
  String? get errorMessage => _errorMessage;
  String? get selectedModel => _selectedModel ?? GroqModels.getDefaultModel();
  GroqService get service => _groqService;
  bool get hasAttemptedAutoInit => _hasAttemptedAutoInit;

  GroqProvider() : _secureStorage = SecureStorageService() {
    // Auto-initialize from secure storage on creation
    _autoInitialize();
  }

  Future<void> _autoInitialize() async {
    if (_hasAttemptedAutoInit) return;
    
    _isAutoInitializing = true;
    _hasAttemptedAutoInit = true;
    notifyListeners();

    try {
      final hasKey = await _secureStorage.hasGroqApiKey();
      if (hasKey) {
        await initializeFromSecureStorage();
      }
    } catch (e) {
      // Silent fail for auto-initialization
      debugPrint('Auto-initialization failed: $e');
    } finally {
      _isAutoInitializing = false;
      notifyListeners();
    }
  }

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

  Future<bool> testConnectionWithModel(String apiKey, String model) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Test with specific model
      final testService = GroqService();
      await testService.initialize(apiKey);
      
      // Try a simple request with the specified model
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

  void setSelectedModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  void clearApiKey() {
    _groqService.clearApiKey();
    _secureStorage.clearGroqApiKey();
    _isInitialized = false;
    _errorMessage = null;
    _selectedModel = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> retryInitialization() async {
    _hasAttemptedAutoInit = false;
    await _autoInitialize();
  }
}