import 'package:flutter/foundation.dart';
import '../services/reminder_service.dart';

class ReminderProvider with ChangeNotifier {
  final ReminderService _reminderService = ReminderService();

  bool _isEnabled = false;
  String _reminderTime = '09:00';
  List<int> _reminderDays = [1, 2, 3, 4, 5];
  String _frequency = 'daily';
  bool _isLoading = false;
  String? _errorMessage;

  bool get isEnabled => _isEnabled;
  String get reminderTime => _reminderTime;
  List<int> get reminderDays => _reminderDays;
  String get frequency => _frequency;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _reminderService.initialize();
      _isEnabled = _reminderService.isEnabled;
      _reminderTime = _reminderService.reminderTime;
      _reminderDays = _reminderService.reminderDays;
      _frequency = _reminderService.frequency;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reminderService.setEnabled(enabled);
      _isEnabled = enabled;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setReminderTime(String time) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reminderService.setReminderTime(time);
      _reminderTime = time;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setReminderDays(List<int> days) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reminderService.setReminderDays(days);
      _reminderDays = days;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setFrequency(String frequency) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reminderService.setFrequency(frequency);
      _frequency = frequency;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestPermissions() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _reminderService.requestPermissions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> arePermissionsGranted() async {
    return await _reminderService.arePermissionsGranted();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
