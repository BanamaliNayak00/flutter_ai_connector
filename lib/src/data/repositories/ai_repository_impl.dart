import '../../domain/repositories/ai_repository.dart';
import '../../domain/entities/ai_config.dart';
import '../../data/datasources/ai_data_source.dart';

class AIRepositoryImpl implements AIRepository {
  final AIDataSource dataSource;

  AIRepositoryImpl({required this.dataSource});

  @override
  Future<String> getResponse(
    String prompt,
    AIConfig config, {
    String? attachmentPath,
    String? attachmentType,
  }) {
    return dataSource.getResponse(
      prompt,
      config,
      attachmentPath: attachmentPath,
      attachmentType: attachmentType,
    );
  }

  @override
  Stream<String> streamResponse(String prompt, AIConfig config) {
    return dataSource.streamResponse(prompt, config);
  }
}
