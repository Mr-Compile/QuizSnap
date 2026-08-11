// Supported Groq models with fallback priority
class GroqModels {
  static const String llama33_70bVersatile = 'llama-3.3-70b-versatile';
  static const String llama31_70bVersatile = 'llama-3.1-70b-versatile';
  static const String mixtral8x7bInstruct = 'mixtral-8x7b-instruct';
  static const String gemma2_9bIt = 'gemma2-9b-it';
  
  static const List<String> supportedModels = [
    llama33_70bVersatile,
    llama31_70bVersatile,
    mixtral8x7bInstruct,
    gemma2_9bIt,
  ];
  
  static String getFallbackModel() => llama33_70bVersatile;
  static String getDefaultModel() => llama33_70bVersatile;
  
  static String getDisplayName(String model) {
    switch (model) {
      case llama33_70bVersatile:
        return 'Llama 3.3 70B (Versatile)';
      case llama31_70bVersatile:
        return 'Llama 3.1 70B (Versatile)';
      case mixtral8x7bInstruct:
        return 'Mixtral 8x7B (Instruct)';
      case gemma2_9bIt:
        return 'Gemma 2 9B (It)';
      default:
        return model;
    }
  }
}