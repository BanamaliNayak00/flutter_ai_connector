enum AIProvider { openai, gemini, groq }

class AIConfig {
  final String apiKey;
  final AIProvider provider;
  final String? modelId;
  final String? baseUrl;
  final String? systemPrompt;
  final bool isMultimodal;

  const AIConfig({
    required this.apiKey,
    required this.provider,
    this.modelId,
    this.baseUrl,
    this.systemPrompt,
    this.isMultimodal = false,
  });
}
