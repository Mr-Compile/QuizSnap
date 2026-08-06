import 'package:flutter/foundation.dart';
import '../services/groq_service.dart';

class GroqProvider with ChangeNotifier {
  final GroqService _groqService = GroqService();
  
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

  void clearApiKey() {
    _groqService.clearApiKey();
    _isInitialized = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}