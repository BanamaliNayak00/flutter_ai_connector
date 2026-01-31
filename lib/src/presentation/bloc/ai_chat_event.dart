import 'package:equatable/equatable.dart';
import '../../domain/entities/ai_config.dart';
import 'ai_chat_state.dart';

abstract class AiChatEvent extends Equatable {
  const AiChatEvent();

  @override
  List<Object?> get props => [];
}

class ApiKeyChanged extends AiChatEvent {
  final AIConfig config;
  const ApiKeyChanged(this.config);

  @override
  List<Object> get props => [config];
}

class SendMessage extends AiChatEvent {
  final String content;
  const SendMessage(this.content);

  @override
  List<Object> get props => [content];
}

class ToggleVoice extends AiChatEvent {}

class VoiceInput extends AiChatEvent {
  final String text;
  const VoiceInput(this.text);
  @override
  List<Object> get props => [text];
}

class AttachmentSelected extends AiChatEvent {
  final String? path;
  final String? type; // 'image', 'file'
  const AttachmentSelected(this.path, this.type);
  @override
  List<Object?> get props => [path, type];
}

class UpdateAnimation extends AiChatEvent {
  final AiAnimationState state;
  const UpdateAnimation(this.state);
  @override
  List<Object> get props => [state];
}

class ChunkReceived extends AiChatEvent {
  final String chunk;
  const ChunkReceived(this.chunk);
  @override
  List<Object> get props => [chunk];
}

class GenerationCompleted extends AiChatEvent {
  final String fullResponse;
  const GenerationCompleted(this.fullResponse);
  @override
  List<Object> get props => [fullResponse];
}

class GenerationFailed extends AiChatEvent {
  final String error;
  const GenerationFailed(this.error);
  @override
  @override
  List<Object> get props => [error];
}

class StopTts extends AiChatEvent {
  const StopTts();
  @override
  List<Object?> get props => [];
}

class SpeakMessage extends AiChatEvent {
  final String content;
  const SpeakMessage(this.content);
  @override
  List<Object> get props => [content];
}
