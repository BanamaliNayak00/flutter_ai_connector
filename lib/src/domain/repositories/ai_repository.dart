import '../entities/ai_config.dart';

abstract class AIRepository {
  /// Stream responses from the AI provider.
  Stream<String> streamResponse(String prompt, AIConfig config);

  /// Get a single response from the AI provider.
  Future<String> getResponse(
    String prompt,
    AIConfig config, {
    String? attachmentPath,
    String? attachmentType,
  });
}
