import 'package:flutter/foundation.dart';

/// Tracks whether the user is currently in a focus session (study or exam).
///
/// When [isFocusMode] is true, the session inactivity timer and warning
/// dialog are suspended so the user can focus without interruption.
///
/// Set [isStudyActive] = true when a study session starts, false when it ends.
/// Set [isExamActive] = true when an exam starts, false when it is
/// submitted, abandoned, or finished.
class FocusModeProvider extends ChangeNotifier {
  bool _isStudyActive = false;
  bool _isExamActive = false;

  bool get isStudyActive => _isStudyActive;
  bool get isExamActive => _isExamActive;

  /// True when the user is inside a study session or exam.
  bool get isFocusMode => _isStudyActive || _isExamActive;

  void enterStudy() {
    if (_isStudyActive) return;
    _isStudyActive = true;
    debugPrint('[FocusMode] enterStudy — focus mode active');
    notifyListeners();
  }

  void exitStudy() {
    if (!_isStudyActive) return;
    _isStudyActive = false;
    debugPrint('[FocusMode] exitStudy — focus mode: $isFocusMode');
    notifyListeners();
  }

  void enterExam() {
    if (_isExamActive) return;
    _isExamActive = true;
    debugPrint('[FocusMode] enterExam — focus mode active');
    notifyListeners();
  }

  void exitExam() {
    if (!_isExamActive) return;
    _isExamActive = false;
    debugPrint('[FocusMode] exitExam — focus mode: $isFocusMode');
    notifyListeners();
  }
}
