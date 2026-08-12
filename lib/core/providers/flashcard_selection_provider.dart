import 'package:flutter/material.dart';

/// Tracks multi-select state for flashcards inside a deck.
///
/// This is a short-lived selection provider scoped to the current deck view.
/// Call [activate] with a [deckId] before using it, and [clear] when leaving.
class FlashcardSelectionProvider with ChangeNotifier {
  int? _activeDeckId;
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;

  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);
  bool get isSelectionMode => _isSelectionMode;
  bool get hasSelection => _selectedIds.isNotEmpty;
  int get selectedCount => _selectedIds.length;

  bool isSelected(int id) => _selectedIds.contains(id);

  void activate(int deckId) {
    if (_activeDeckId == deckId) return;
    _activeDeckId = deckId;
    _selectedIds.clear();
    _isSelectionMode = false;
    // Avoid notifying during build; post-frame listeners will rebuild after the phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  void enterSelection() {
    if (!_isSelectionMode) {
      _isSelectionMode = true;
      notifyListeners();
    }
  }

  void exitSelection() {
    _isSelectionMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  void toggle(int id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    if (_selectedIds.isEmpty) {
      _isSelectionMode = false;
    } else {
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  void select(int id) {
    _selectedIds.add(id);
    if (_selectedIds.length == 1) {
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  void selectAll(List<int> ids) {
    _selectedIds.addAll(ids);
    _isSelectionMode = true;
    notifyListeners();
  }

  void clear() {
    _selectedIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }
}
