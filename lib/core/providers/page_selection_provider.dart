import 'package:flutter/foundation.dart';
import '../../core/utils/page_range_parser.dart';

/// Tracks selected PDF pages and ranges for the thumbnail page grid.
class PageSelectionProvider with ChangeNotifier {
  int _totalPages = 0;
  final Set<int> _selectedPages = {};
  String _rangeInput = '';

  int get totalPages => _totalPages;
  Set<int> get selectedPages => Set.unmodifiable(_selectedPages);
  int get selectedCount => _selectedPages.length;
  String get rangeInput => _rangeInput;

  void setTotalPages(int total) {
    _totalPages = total;
    notifyListeners();
  }

  void applyRangeInput(String input) {
    _rangeInput = input;
    _selectedPages.addAll(PageRangeParser.parse(input, totalPages: _totalPages));
    notifyListeners();
  }

  void togglePage(int page) {
    if (_selectedPages.contains(page)) {
      _selectedPages.remove(page);
    } else {
      _selectedPages.add(page);
    }
    _rangeInput = PageRangeParser.format(_selectedPages);
    notifyListeners();
  }

  void selectAll() {
    _selectedPages.addAll(List.generate(_totalPages, (i) => i + 1));
    _rangeInput = PageRangeParser.format(_selectedPages);
    notifyListeners();
  }

  void clear() {
    _selectedPages.clear();
    _rangeInput = '';
    notifyListeners();
  }

  /// Range selection: select from [start] to [end] inclusive.
  void selectRange(int start, int end) {
    final lower = start.clamp(1, _totalPages);
    final upper = end.clamp(1, _totalPages);
    for (int i = lower; i <= upper; i++) {
      _selectedPages.add(i);
    }
    _rangeInput = PageRangeParser.format(_selectedPages);
    notifyListeners();
  }
}
