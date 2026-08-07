import 'package:shared_preferences/shared_preferences.dart';

/// AppStateManager handles persistent state across app sessions
/// 
/// This utility manages:
/// - Current tab selection
/// - Search queries
/// - Selected filters
/// - Theme preferences
/// - User preferences
class AppStateManager {
  AppStateManager._();

  static final AppStateManager _instance = AppStateManager._();
  factory AppStateManager() => _instance;

  SharedPreferences? _prefs;

  // Keys
  static const String _currentTabKey = 'current_tab';
  static const String _lastSearchQueryKey = 'last_search_query';
  static const String _selectedFilterKey = 'selected_filter';
  static const String _selectedSortKey = 'selected_sort';
  static const String _lastDeckIdKey = 'last_deck_id';
  static const String _lastStudyModeKey = 'last_study_mode';

  /// Initialize the state manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get current tab index
  int getCurrentTab() {
    return _prefs?.getInt(_currentTabKey) ?? 0;
  }

  /// Set current tab index
  Future<void> setCurrentTab(int index) async {
    await _prefs?.setInt(_currentTabKey, index);
  }

  /// Get last search query
  String? getLastSearchQuery() {
    return _prefs?.getString(_lastSearchQueryKey);
  }

  /// Set last search query
  Future<void> setLastSearchQuery(String query) async {
    await _prefs?.setString(_lastSearchQueryKey, query);
  }

  /// Get selected filter
  String? getSelectedFilter() {
    return _prefs?.getString(_selectedFilterKey);
  }

  /// Set selected filter
  Future<void> setSelectedFilter(String filter) async {
    await _prefs?.setString(_selectedFilterKey, filter);
  }

  /// Get selected sort option
  String? getSelectedSort() {
    return _prefs?.getString(_selectedSortKey);
  }

  /// Set selected sort option
  Future<void> setSelectedSort(String sort) async {
    await _prefs?.setString(_selectedSortKey, sort);
  }

  /// Get last viewed deck ID
  int? getLastDeckId() {
    return _prefs?.getInt(_lastDeckIdKey);
  }

  /// Set last viewed deck ID
  Future<void> setLastDeckId(int deckId) async {
    await _prefs?.setInt(_lastDeckIdKey, deckId);
  }

  /// Get last study mode
  String? getLastStudyMode() {
    return _prefs?.getString(_lastStudyModeKey);
  }

  /// Set last study mode
  Future<void> setLastStudyMode(String mode) async {
    await _prefs?.setString(_lastStudyModeKey, mode);
  }

  /// Clear all state
  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  /// Clear navigation-related state only
  Future<void> clearNavigationState() async {
    await _prefs?.remove(_currentTabKey);
    await _prefs?.remove(_lastSearchQueryKey);
    await _prefs?.remove(_selectedFilterKey);
    await _prefs?.remove(_selectedSortKey);
    await _prefs?.remove(_lastDeckIdKey);
    await _prefs?.remove(_lastStudyModeKey);
  }
}

/// QuizStateManager handles quiz session state persistence
class QuizStateManager {
  QuizStateManager._();

  static final QuizStateManager _instance = QuizStateManager._();
  factory QuizStateManager() => _instance;

  SharedPreferences? _prefs;

  // Keys
  static const String _activeQuizIdKey = 'active_quiz_id';
  static const String _quizDeckIdKey = 'quiz_deck_id';
  static const String _quizQuestionIndexKey = 'quiz_question_index';
  static const String _quizAnswersKey = 'quiz_answers';
  static const String _quizStartTimeKey = 'quiz_start_time';
  static const String _quizTimeRemainingKey = 'quiz_time_remaining';

  /// Initialize the quiz state manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save active quiz state
  Future<void> saveQuizState({
    required String quizId,
    required int deckId,
    required int questionIndex,
    required Map<int, int> answers,
    required DateTime startTime,
    required Duration timeRemaining,
  }) async {
    await _prefs?.setString(_activeQuizIdKey, quizId);
    await _prefs?.setInt(_quizDeckIdKey, deckId);
    await _prefs?.setInt(_quizQuestionIndexKey, questionIndex);
    await _prefs?.setString(_quizAnswersKey, _encodeAnswers(answers));
    await _prefs?.setString(_quizStartTimeKey, startTime.toIso8601String());
    await _prefs?.setInt(_quizTimeRemainingKey, timeRemaining.inSeconds);
  }

  /// Load active quiz state
  Map<String, dynamic>? loadQuizState() {
    final quizId = _prefs?.getString(_activeQuizIdKey);
    if (quizId == null) return null;

    return {
      'quizId': quizId,
      'deckId': _prefs?.getInt(_quizDeckIdKey),
      'questionIndex': _prefs?.getInt(_quizQuestionIndexKey) ?? 0,
      'answers': _decodeAnswers(_prefs?.getString(_quizAnswersKey) ?? ''),
      'startTime': DateTime.tryParse(_prefs?.getString(_quizStartTimeKey) ?? ''),
      'timeRemaining': Duration(seconds: _prefs?.getInt(_quizTimeRemainingKey) ?? 0),
    };
  }

  /// Clear quiz state
  Future<void> clearQuizState() async {
    await _prefs?.remove(_activeQuizIdKey);
    await _prefs?.remove(_quizDeckIdKey);
    await _prefs?.remove(_quizQuestionIndexKey);
    await _prefs?.remove(_quizAnswersKey);
    await _prefs?.remove(_quizStartTimeKey);
    await _prefs?.remove(_quizTimeRemainingKey);
  }

  /// Check if there's an active quiz
  bool hasActiveQuiz() {
    return _prefs?.containsKey(_activeQuizIdKey) ?? false;
  }

  String _encodeAnswers(Map<int, int> answers) {
    return answers.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  Map<int, int> _decodeAnswers(String encoded) {
    if (encoded.isEmpty) return {};
    return Map.fromEntries(
      encoded.split(',').map((pair) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          return MapEntry(int.parse(parts[0]), int.parse(parts[1]));
        }
        return MapEntry(0, 0);
      }),
    );
  }
}

/// FormDraftManager handles form draft saving for long forms
class FormDraftManager {
  FormDraftManager._();

  static final FormDraftManager _instance = FormDraftManager._();
  factory FormDraftManager() => _instance;

  SharedPreferences? _prefs;

  /// Initialize the form draft manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save form draft
  Future<void> saveDraft(String formKey, Map<String, dynamic> data) async {
    final json = _encodeMap(data);
    await _prefs?.setString('draft_$formKey', json);
  }

  /// Load form draft
  Map<String, dynamic>? loadDraft(String formKey) {
    final json = _prefs?.getString('draft_$formKey');
    if (json == null) return null;
    return _decodeMap(json);
  }

  /// Clear form draft
  Future<void> clearDraft(String formKey) async {
    await _prefs?.remove('draft_$formKey');
  }

  /// Check if draft exists
  bool hasDraft(String formKey) {
    return _prefs?.containsKey('draft_$formKey') ?? false;
  }

  String _encodeMap(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}:${e.value}').join('|');
  }

  Map<String, dynamic> _decodeMap(String encoded) {
    if (encoded.isEmpty) return {};
    return Map.fromEntries(
      encoded.split('|').map((pair) {
        final parts = pair.split(':');
        if (parts.length >= 2) {
          final key = parts[0];
          final value = parts.sublist(1).join(':');
          return MapEntry(key, value);
        }
        return MapEntry('', '');
      }),
    );
  }
}