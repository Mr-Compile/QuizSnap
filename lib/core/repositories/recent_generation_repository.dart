import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prompt_template.dart';
import '../models/recent_generation.dart';

/// Offline-first repository for recently-generated AI question sets.
///
/// Data is persisted in SharedPreferences as JSON and exposed through a
/// ChangeNotifier for reactive UI updates.
class RecentGenerationRepository with ChangeNotifier {
  static const String _key = 'recent_generations';
  final SharedPreferences _prefs;
  List<RecentGeneration> _generations = [];

  RecentGenerationRepository(this._prefs) {
    _load();
  }

  List<RecentGeneration> get generations => List.unmodifiable(_generations);

  /// Returns the most recent [limit] generations (already sorted newest-first).
  List<RecentGeneration> getRecentGenerations(int limit) {
    return List.unmodifiable(_generations.take(limit));
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _generations = [];
      return;
    }
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _generations = list.map(RecentGeneration.fromJson).toList();
      _sort();
    } catch (e) {
      debugPrint('Error loading recent generations: $e');
      _generations = [];
    }
  }

  Future<void> _save() async {
    final list = _generations.map((g) => g.toJson()).toList();
    await _prefs.setString(_key, jsonEncode(list));
  }

  void _sort() {
    _generations.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
  }

  Future<void> addGeneration(RecentGeneration generation) async {
    _generations.add(generation);
    _sort();
    await _save();
    notifyListeners();
  }

  Future<void> updateSavedDeckId(String id, int deckId) async {
    final index = _generations.indexWhere((g) => g.id == id);
    if (index >= 0) {
      _generations[index] = _generations[index].copyWith(savedDeckId: deckId);
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteGeneration(String id) async {
    _generations.removeWhere((g) => g.id == id);
    await _save();
    notifyListeners();
  }

  RecentGeneration? getById(String id) {
    try {
      return _generations.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Creates a title from a source string and count.
  static String buildTitle(String source, PromptType type, int count) {
    final typeName = type.displayName;
    final fileName = source.split('/').last;
    return '$typeName ($count questions) from $fileName';
  }
}
