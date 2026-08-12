import 'package:flutter/foundation.dart';

/// Tracks a single selected text snippet for the smart document analysis flow.
class HighlightedSelectionProvider with ChangeNotifier {
  String _selectedText = '';
  int _characterCount = 0;

  String get selectedText => _selectedText;
  int get characterCount => _characterCount;
  bool get hasSelection => _selectedText.trim().isNotEmpty;

  void setSelection(String text) {
    _selectedText = text;
    _characterCount = text.length;
    notifyListeners();
  }

  void clear() {
    _selectedText = '';
    _characterCount = 0;
    notifyListeners();
  }
}
