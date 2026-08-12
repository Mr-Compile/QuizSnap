// Supported Groq models with fallback priority
class GroqModels {
  // Default / preferred model for QuizSnap
  static const String llama33_70bVersatile = 'llama-3.3-70b-versatile';

  // Fallback models, ordered by preference
  static const String llama32_90bVisionInstruct = 'llama-3.2-90b-vision-instruct';
  static const String llama31_70bVersatile = 'llama-3.1-70b-versatile';
  static const String llama31_8bInstant = 'llama-3.1-8b-instant';
  static const String qwenQwen36_27b = 'qwen/qwen3.6-27b';
  static const String openaiGptOss120b = 'openai/gpt-oss-120b';
  static const String openaiGptOss20b = 'openai/gpt-oss-20b';

  static const List<String> supportedModels = [
    llama33_70bVersatile,
    llama32_90bVisionInstruct,
    llama31_70bVersatile,
    llama31_8bInstant,
    qwenQwen36_27b,
    openaiGptOss120b,
    openaiGptOss20b,
  ];

  static List<String> getFallbackChain({String? preferred}) {
    final chain = <String>[];
    if (preferred != null && supportedModels.contains(preferred)) {
      chain.add(preferred);
    }
    for (final model in supportedModels) {
      if (!chain.contains(model)) {
        chain.add(model);
      }
    }
    return chain;
  }

  static String getFallbackModel() => llama31_70bVersatile;
  static String getDefaultModel() => llama33_70bVersatile;

  static String getDisplayName(String model) {
    switch (model) {
      case llama33_70bVersatile:
        return 'Llama 3.3 70B';
      case llama32_90bVisionInstruct:
        return 'Llama 3.2 90B Vision';
      case llama31_70bVersatile:
        return 'Llama 3.1 70B';
      case llama31_8bInstant:
        return 'Llama 3.1 8B Instant';
      case qwenQwen36_27b:
        return 'Qwen 3.6 27B';
      case openaiGptOss120b:
        return 'OpenAI GPT-OSS 120B';
      case openaiGptOss20b:
        return 'OpenAI GPT-OSS 20B';
      default:
        return model;
    }
  }
}
