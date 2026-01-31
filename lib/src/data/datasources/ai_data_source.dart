import '../../domain/entities/ai_config.dart';

abstract class AIDataSource {
  Future<String> getResponse(
    String prompt,
    AIConfig config, {
    String? attachmentPath,
    String? attachmentType,
  });
  Stream<String> streamResponse(String prompt, AIConfig config);
}
