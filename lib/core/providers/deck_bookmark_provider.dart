import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory + SharedPreferences provider for bookmarked deck IDs.
///
/// This does not touch the Drift schema; deck bookmarks are stored as a list
/// of integer IDs in SharedPreferences.
class DeckBookmarkProvider with ChangeNotifier {
  static const String _key = 'bookmarked_deck_ids';
  final SharedPreferences _prefs;
  final Set<int> _bookmarkedIds = {};

  DeckBookmarkProvider(this._prefs) {
    _load();
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).cast<int>();
        _bookmarkedIds.addAll(list);
      } catch (e) {
        debugPrint('Error loading deck bookmarks: $e');
      }
    }
  }

  Future<void> _save() async {
    await _prefs.setString(_key, jsonEncode(_bookmarkedIds.toList()));
  }

  bool isBookmarked(int deckId) => _bookmarkedIds.contains(deckId);

  Set<int> get bookmarkedIds => Set.unmodifiable(_bookmarkedIds);

  Future<void> addBookmark(int deckId) async {
    if (_bookmarkedIds.add(deckId)) {
      await _save();
      notifyListeners();
    }
  }

  Future<void> removeBookmark(int deckId) async {
    if (_bookmarkedIds.remove(deckId)) {
      await _save();
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(int deckId) async {
    if (_bookmarkedIds.contains(deckId)) {
      await removeBookmark(deckId);
    } else {
      await addBookmark(deckId);
    }
  }

  /// Sorts a list of decks so that bookmarked decks appear first.
  List<T> sortBookmarkedFirst<T extends Object>(
    List<T> decks,
    int Function(T) deckIdGetter,
  ) {
    final sorted = List<T>.from(decks);
    sorted.sort((a, b) {
      final aBookmarked = isBookmarked(deckIdGetter(a)) ? 1 : 0;
      final bBookmarked = isBookmarked(deckIdGetter(b)) ? 1 : 0;
      return bBookmarked - aBookmarked;
    });
    return sorted;
  }
}
