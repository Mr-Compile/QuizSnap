import 'package:flutter/foundation.dart';
import '../services/ai_quota_service.dart';
import '../providers/database_provider.dart';

class AiQuotaProvider with ChangeNotifier {
  final DatabaseProvider _databaseProvider;
  late final AiQuotaService _quotaService;
  
  QuotaStatus? _quotaStatus;
  bool _isLoading = false;
  String? _errorMessage;

  AiQuotaProvider(this._databaseProvider) {
    _quotaService = AiQuotaService(_databaseProvider);
    _loadQuotaStatus();
  }

  QuotaStatus? get quotaStatus => _quotaStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AiQuotaService get service => _quotaService;

  bool get canRequest => _quotaStatus?.canRequest ?? true;
  bool get isLow => _quotaStatus?.isLow ?? false;
  int get remaining => _quotaStatus?.remaining ?? 15;

  Future<void> _loadQuotaStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _quotaStatus = await _quotaService.getQuotaStatus();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> incrementUsage() async {
    try {
      final success = await _quotaService.incrementUsage();
      if (success) {
        await _loadQuotaStatus();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshQuota() async {
    await _loadQuotaStatus();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}