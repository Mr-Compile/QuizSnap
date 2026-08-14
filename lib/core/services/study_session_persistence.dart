import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudySessionState {
  final int deckId;
  final String deckName;
  final int currentIndex;
  final bool isRevealed;
  final DateTime? lastStudiedAt;
  final int totalCards;
  final int accumulatedSeconds;

  const StudySessionState({
    required this.deckId,
    required this.deckName,
    required this.currentIndex,
    required this.isRevealed,
    required this.totalCards,
    this.lastStudiedAt,
    this.accumulatedSeconds = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'deckId': deckId,
      'deckName': deckName,
      'currentIndex': currentIndex,
      'isRevealed': isRevealed,
      'totalCards': totalCards,
      'accumulatedSeconds': accumulatedSeconds,
      'lastStudiedAt': lastStudiedAt?.toIso8601String(),
    };
  }

  factory StudySessionState.fromJson(Map<String, dynamic> json) {
    return StudySessionState(
      deckId: json['deckId'] as int,
      deckName: json['deckName'] as String,
      currentIndex: json['currentIndex'] as int,
      isRevealed: json['isRevealed'] as bool,
      totalCards: json['totalCards'] as int,
      accumulatedSeconds: (json['accumulatedSeconds'] as num?)?.toInt() ?? 0,
      lastStudiedAt: json['lastStudiedAt'] != null
          ? DateTime.tryParse(json['lastStudiedAt'] as String)
          : null,
    );
  }

  StudySessionState copyWith({
    int? deckId,
    String? deckName,
    int? currentIndex,
    bool? isRevealed,
    DateTime? lastStudiedAt,
    int? totalCards,
    int? accumulatedSeconds,
  }) {
    return StudySessionState(
      deckId: deckId ?? this.deckId,
      deckName: deckName ?? this.deckName,
      currentIndex: currentIndex ?? this.currentIndex,
      isRevealed: isRevealed ?? this.isRevealed,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      totalCards: totalCards ?? this.totalCards,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
    );
  }
}

/// Persists the active study session to SharedPreferences so it can be resumed.
class StudySessionPersistence {
  static const String _key = 'study_session_state';
  final SharedPreferences _prefs;

  StudySessionPersistence(this._prefs);

  Future<void> save(StudySessionState state) async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  StudySessionState? load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return StudySessionState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }

  bool get hasUnfinishedSession => load() != null;
}
