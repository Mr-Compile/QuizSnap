/// Validates AI-generated explanation responses before they are displayed
/// to the student.
///
/// This is the application-side safety net required by the global output
/// contract. It detects:
/// - Internal reasoning tags (`<think>`, `</think>`)
/// - Chain-of-thought / analysis prefixes
/// - Prompt-template leakage (e.g. "Question Type:", "Task:", "Options:")
/// - Unresolved template variables and placeholders (`$1`, `{question}`, etc.)
///
/// If a response fails validation it must NOT be displayed. The caller should
/// attempt one safe regeneration and then fall back to a deterministic
/// explanation.
class AIResponseValidator {
  AIResponseValidator._();

  /// Patterns that indicate internal reasoning / chain-of-thought leakage.
  static final _reasoningPatterns = <RegExp>[
    RegExp(r'<think>', caseSensitive: false),
    RegExp(r'</think>', caseSensitive: false),
    RegExp(r"here'?s?\s+my\s+thinking\s+process", caseSensitive: false),
    RegExp(r'^reasoning\s*:', caseSensitive: false, multiLine: true),
    RegExp(r'^analysis\s*:', caseSensitive: false, multiLine: true),
    RegExp(r'^task\s*:', caseSensitive: false, multiLine: true),
    RegExp(r'^step\s+\d+', caseSensitive: false, multiLine: true),
    RegExp(r'^let\s+me\s+(think|analyze|reason)', caseSensitive: false, multiLine: true),
    RegExp(r'^my\s+(thinking|reasoning|analysis)\s*:', caseSensitive: false, multiLine: true),
  ];

  /// Patterns that indicate prompt-template content leaked into the response.
  static final _promptLeakagePatterns = <RegExp>[
    RegExp(r'^question\s+type\s*:', caseSensitive: false, multiLine: true),
    RegExp(r'^user'?s?\s+answer\s*:', caseSensitive: false, multiLine: true),
    RegExp(r'^correct\s+answer\s*:', caseSensitive: false, multiLine: true),
    RegExp(r'^options\s*:', caseSensitive: false, multiLine: true),
    RegExp(r'^learning\s+context\s*:', caseSensitive: false, multiLine: true),
    RegExp(r'^difficulty\s*:', caseSensitive: false, multiLine: true),
    RegExp(r'^determine\s+if\s+user'?s?\s+answer\s+is\s+correct', caseSensitive: false, multiLine: true),
    RegExp(r'^source\s+material\s*:', caseSensitive: false, multiLine: true),
    RegExp(r'^application\s+grading\s+result\s*:', caseSensitive: false, multiLine: true),
  ];

  /// Patterns that indicate unresolved template variables / placeholders.
  static final _placeholderPatterns = <RegExp>[
    RegExp(r'\$\d+'),
    RegExp(r'\$answer', caseSensitive: false),
    RegExp(r'\$question', caseSensitive: false),
    RegExp(r'\$correctAnswer', caseSensitive: false),
    RegExp(r'\{question\}', caseSensitive: false),
    RegExp(r'\{answer\}', caseSensitive: false),
    RegExp(r'\{correctAnswer\}', caseSensitive: false),
    RegExp(r'\{studentAnswer\}', caseSensitive: false),
    RegExp(r'\{options\}', caseSensitive: false),
    RegExp(r'\{difficulty\}', caseSensitive: false),
    RegExp(r'\{content\}', caseSensitive: false),
    RegExp(r'\{count\}', caseSensitive: false),
  ];

  /// Validates [response] and returns a [ValidationResult].
  static ValidationResult validate(String? response) {
    if (response == null || response.trim().isEmpty) {
      return ValidationResult.invalid(reason: 'Response is empty or null.');
    }

    final text = response.trim();

    for (final pattern in _reasoningPatterns) {
      if (pattern.hasMatch(text)) {
        return ValidationResult.invalid(
          reason: 'Internal reasoning detected in response.',
        );
      }
    }

    for (final pattern in _promptLeakagePatterns) {
      if (pattern.hasMatch(text)) {
        return ValidationResult.invalid(
          reason: 'Prompt template content detected in response.',
        );
      }
    }

    for (final pattern in _placeholderPatterns) {
      if (pattern.hasMatch(text)) {
        return ValidationResult.invalid(
          reason: 'Unresolved placeholder detected in response.',
        );
      }
    }

    return ValidationResult.valid();
  }
}

/// Result of validating an AI response.
class ValidationResult {
  final bool isValid;
  final String? reason;

  const ValidationResult._({required this.isValid, this.reason});

  factory ValidationResult.valid() => const ValidationResult._(isValid: true);

  factory ValidationResult.invalid({required String reason}) =>
      ValidationResult._(isValid: false, reason: reason);
}
