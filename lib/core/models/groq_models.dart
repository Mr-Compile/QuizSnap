// Supported Groq models with fallback priority
class GroqModels {
  static const String openaiGptOss120b = 'openai/gpt-oss-120b';
  static const String qwenQwen36_27b = 'qwen/qwen3.6-27b';
  static const String llama31_8bInstant = 'llama-3.1-8b-instant';
  static const String openaiGptOss20b = 'openai/gpt-oss-20b';
  
  static const List<String> supportedModels = [
    openaiGptOss120b,
    qwenQwen36_27b,
    llama31_8bInstant,
    openaiGptOss20b,
  ];
  
  static String getFallbackModel() => openaiGptOss120b;
  static String getDefaultModel() => openaiGptOss120b;
  
  static String getDisplayName(String model) {
    switch (model) {
      case openaiGptOss120b:
        return 'OpenAI GPT-OSS 120B';
      case qwenQwen36_27b:
        return 'Qwen 3.6 27B';
      case llama31_8bInstant:
        return 'Llama 3.1 8B Instant';
      case openaiGptOss20b:
        return 'OpenAI GPT-OSS 20B';
      default:
        return model;
    }
  }
}