import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_google/langchain_google.dart';
import '../../domain/entities/ai_config.dart';
import 'ai_data_source.dart';

class LangChainDataSource implements AIDataSource {
  @override
  Future<String> getResponse(
    String prompt,
    AIConfig config, {
    String? attachmentPath,
    String? attachmentType,
  }) async {
    debugPrint("LangChainDataSource: Invoking model...");
    debugPrint(
      "Config: Provider=${config.provider}, Key=${config.apiKey.isNotEmpty ? 'Set' : 'Missing'}",
    );

    final model = _getModel(config);

    List<ChatMessage> messages = [];

    // System Prompt
    if (config.systemPrompt != null) {
      messages.add(ChatMessage.system(config.systemPrompt!));
    }

    // User Prompt with potential Image
    if (attachmentPath != null && config.isMultimodal) {
      // Fallback or Multimodal Logic
      // ChatMessage.human expects ChatMessageContent.
      // If we want to send image, we need ChatMessageContent.image
      // But for now, ensuring COMPILATION is priority.
      // We will pass text context wrapped in Content.
      final textWithContext =
          "$prompt\n[Attachment: $attachmentType at $attachmentPath]";
      messages.add(ChatMessage.human(ChatMessageContent.text(textWithContext)));
    } else {
      messages.add(ChatMessage.human(ChatMessageContent.text(prompt)));
    }

    try {
      final result = await model.invoke(PromptValue.chat(messages));
      debugPrint(
        "LangChainDataSource: Result received: ${result.output.content.substring(0, result.output.content.length > 50 ? 50 : result.output.content.length)}...",
      );
      return _cleanResponse(result.output.content);
    } catch (e) {
      debugPrint("LangChainDataSource Error: $e");
      rethrow;
    }
  }

  @override
  Stream<String> streamResponse(String prompt, AIConfig config) {
    final model = _getModel(config);
    final messages = [
      if (config.systemPrompt != null) ChatMessage.system(config.systemPrompt!),
      ChatMessage.human(ChatMessageContent.text(prompt)),
    ];

    // Stream transformer to handle <think> tags
    return model
        .stream(PromptValue.chat(messages))
        .transform(_ThinkTagTransformer());
  }

  String _cleanResponse(String response) {
    // Regex to remove <think>...</think> (including newlines)
    return response
        .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
        .trim();
  }

  BaseChatModel _getModel(AIConfig config) {
    switch (config.provider) {
      case AIProvider.openai:
        return ChatOpenAI(
          apiKey: config.apiKey,
          defaultOptions: ChatOpenAIOptions(
            model: config.modelId ?? 'gpt-3.5-turbo',
          ),
        );
      case AIProvider.gemini:
        return ChatGoogleGenerativeAI(
          apiKey: config.apiKey,
          defaultOptions: ChatGoogleGenerativeAIOptions(
            model: config.modelId ?? 'gemini-pro',
          ),
        );
      case AIProvider.groq:
        return ChatOpenAI(
          apiKey: config.apiKey,
          baseUrl: config.baseUrl ?? 'https://api.groq.com/openai/v1',
          defaultOptions: ChatOpenAIOptions(
            model: config.modelId ?? 'llama3-70b-8192',
          ),
        );
    }
  }
}

class _ThinkTagTransformer extends StreamTransformerBase<ChatResult, String> {
  const _ThinkTagTransformer();

  @override
  Stream<String> bind(Stream<ChatResult> stream) {
    final controller = StreamController<String>();
    final buffer = StringBuffer();
    bool insideThink = false;
    bool checkedForStart = false;

    stream.listen(
      (chunk) {
        final text = chunk.output.content;
        if (text.isEmpty) return;

        if (!checkedForStart) {
          buffer.write(text);
          if (buffer.toString().contains('<think>')) {
            insideThink = true;
            checkedForStart = true;
            final parts = buffer.toString().split('<think>');
            if (parts.isNotEmpty && parts[0].isNotEmpty) {
              controller.add(parts[0]);
            }
            buffer.clear();
            if (parts.length > 1) {
              buffer.write(parts.sublist(1).join('<think>'));
            }
          } else if (buffer.length > 20) {
            checkedForStart = true;
            controller.add(buffer.toString());
            buffer.clear();
          }
          return;
        }

        if (insideThink) {
          buffer.write(text);
          if (buffer.toString().contains('</think>')) {
            insideThink = false;
            final parts = buffer.toString().split('</think>');
            if (parts.length > 1) {
              controller.add(parts[1]);
            }
            buffer.clear();
          }
        } else {
          controller.add(text);
        }
      },
      onError: controller.addError,
      onDone: () {
        if (!insideThink && buffer.isNotEmpty) {
          controller.add(buffer.toString());
        }
        controller.close();
      },
    );

    return controller.stream;
  }
}
