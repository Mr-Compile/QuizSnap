import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam.dart';

class ExplanationCacheService {
  static const String _cachePrefix = 'explanation_cache_';
  static const String _cacheIndexKey = 'explanation_cache_index';
  static const Duration _cacheExpiry = Duration(days: 7);

  final SharedPreferences _prefs;
  final Map<String, CachedExplanation> _memoryCache = {};

  ExplanationCacheService(this._prefs);

  Future<void> initialize() async {
    await _loadCacheIndex();
  }

  Future<bool> hasExplanation(String questionId) async {
    if (_memoryCache.containsKey(questionId)) {
      return true;
    }

    final cached = await _getCachedExplanation(questionId);
    return cached != null && !_isExpired(cached);
  }

  Future<String?> getExplanation(String questionId) async {
    // Check memory cache first
    if (_memoryCache.containsKey(questionId)) {
      final cached = _memoryCache[questionId]!;
      if (!_isExpired(cached)) {
        return cached.explanation;
      }
      _memoryCache.remove(questionId);
    }

    // Check persistent cache
    final cached = await _getCachedExplanation(questionId);
    if (cached != null && !_isExpired(cached)) {
      _memoryCache[questionId] = cached;
      return cached.explanation;
    }

    return null;
  }

  Future<void> cacheExplanation({
    required String questionId,
    required String explanation,
    required ExamQuestion question,
  }) async {
    final cached = CachedExplanation(
      questionId: questionId,
      explanation: explanation,
      question: question,
      cachedAt: DateTime.now(),
    );

    // Store in memory
    _memoryCache[questionId] = cached;

    // Store persistently
    await _cacheExplanationPersistently(cached);
    await _updateCacheIndex(questionId);
  }

  Future<List<CachedExplanation>> getAllCachedExplanations() async {
    final index = await _getCacheIndex();
    final explanations = <CachedExplanation>[];

    for (final questionId in index) {
      final cached = await _getCachedExplanation(questionId);
      if (cached != null && !_isExpired(cached)) {
        explanations.add(cached);
      }
    }

    return explanations;
  }

  Future<void> clearExpiredCache() async {
    final index = await _getCacheIndex();
    final validIds = <String>[];

    for (final questionId in index) {
      final cached = await _getCachedExplanation(questionId);
      if (cached != null && !_isExpired(cached)) {
        validIds.add(questionId);
      } else {
        await _removeCachedExplanation(questionId);
      }
    }

    await _saveCacheIndex(validIds);
    _memoryCache.removeWhere((key, value) => _isExpired(value));
  }

  Future<void> clearCache() async {
    final index = await _getCacheIndex();
    for (final questionId in index) {
      await _removeCachedExplanation(questionId);
    }
    await _saveCacheIndex([]);
    _memoryCache.clear();
  }

  Future<void> clearExplanation(String questionId) async {
    _memoryCache.remove(questionId);
    await _removeCachedExplanation(questionId);
    await _removeFromCacheIndex(questionId);
  }

  Future<int> getCacheSize() async {
    final index = await _getCacheIndex();
    return index.length;
  }

  Future<int> getCacheSizeInBytes() async {
    final index = await _getCacheIndex();
    int totalSize = 0;

    for (final questionId in index) {
      final key = _getCacheKey(questionId);
      final data = _prefs.getString(key);
      if (data != null) {
        totalSize += data.length;
      }
    }

    return totalSize;
  }

  Future<CachedExplanation?> _getCachedExplanation(String questionId) async {
    final key = _getCacheKey(questionId);
    final data = _prefs.getString(key);
    if (data == null) return null;

    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return CachedExplanation.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheExplanationPersistently(CachedExplanation cached) async {
    final key = _getCacheKey(cached.questionId);
    final data = jsonEncode(cached.toJson());
    await _prefs.setString(key, data);
  }

  Future<void> _removeCachedExplanation(String questionId) async {
    final key = _getCacheKey(questionId);
    await _prefs.remove(key);
  }

  Future<List<String>> _getCacheIndex() async {
    final indexData = _prefs.getString(_cacheIndexKey);
    if (indexData == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(indexData);
      return decoded.cast<String>();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveCacheIndex(List<String> index) async {
    final indexData = jsonEncode(index);
    await _prefs.setString(_cacheIndexKey, indexData);
  }

  Future<void> _updateCacheIndex(String questionId) async {
    final index = await _getCacheIndex();
    if (!index.contains(questionId)) {
      index.add(questionId);
      await _saveCacheIndex(index);
    }
  }

  Future<void> _removeFromCacheIndex(String questionId) async {
    final index = await _getCacheIndex();
    index.remove(questionId);
    await _saveCacheIndex(index);
  }

  Future<void> _loadCacheIndex() async {
    final index = await _getCacheIndex();
    for (final questionId in index) {
      final cached = await _getCachedExplanation(questionId);
      if (cached != null && !_isExpired(cached)) {
        _memoryCache[questionId] = cached;
      }
    }
  }

  String _getCacheKey(String questionId) {
    return '$_cachePrefix$questionId';
  }

  bool _isExpired(CachedExplanation cached) {
    return DateTime.now().difference(cached.cachedAt) > _cacheExpiry;
  }
}

class CachedExplanation {
  final String questionId;
  final String explanation;
  final ExamQuestion question;
  final DateTime cachedAt;

  CachedExplanation({
    required this.questionId,
    required this.explanation,
    required this.question,
    required this.cachedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'explanation': explanation,
      'question': question.toJson(),
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  factory CachedExplanation.fromJson(Map<String, dynamic> json) {
    return CachedExplanation(
      questionId: json['questionId'] as String,
      explanation: json['explanation'] as String,
      question: ExamQuestion.fromJson(json['question'] as Map<String, dynamic>),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }

  bool get isExpired {
    return DateTime.now().difference(cachedAt) > const Duration(days: 7);
  }
}
