// Supported Groq models with fallback priority
class GroqModels {
  static const String llama31_8bInstant = 'llama-3.1-8b-instant';
  static const String llama31_70bVersatile = 'llama-3.1-70b-versatile';
  static const String mixtral8x7bInstruct = 'mixtral-8x7b-instruct';
  static const String gemma7bInstruct = 'gemma-7b-instruct';
  
  static const List<String> supportedModels = [
    llama31_8bInstant,
    llama31_70bVersatile,
    mixtral8x7bInstruct,
    gemma7bInstruct,
  ];
  
  static String getFallbackModel() => llama31_8bInstant;
  static String getDefaultModel() => llama31_8bInstant;
  
  static String getDisplayName(String model) {
    switch (model) {
      case llama31_8bInstant:
        return 'Llama 3.1 8B (Instant)';
      case llama31_70bVersatile:
        return 'Llama 3.1 70B (Versatile)';
      case mixtral8x7bInstruct:
        return 'Mixtral 8x7B (Instruct)';
      case gemma7bInstruct:
        return 'Gemma 7B (Instruct)';
      default:
        return model;
    }
  }
}