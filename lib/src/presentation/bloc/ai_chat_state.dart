import 'package:equatable/equatable.dart';
import '../../domain/entities/ai_message.dart';

enum AiChatStatus { initial, loading, success, failure }

enum AiAnimationState { idle, listening, thinking, speaking }

class AiChatState extends Equatable {
  final AiChatStatus status;
  final List<AIMessage> messages;
  final AiAnimationState animationState;
  final String? errorMessage;

  final bool isVoiceEnabled;
  final String? attachmentPath;
  final String? attachmentType;

  const AiChatState({
    this.status = AiChatStatus.initial,
    this.messages = const [],
    this.animationState = AiAnimationState.idle,
    this.isVoiceEnabled = false,
    this.errorMessage,
    this.attachmentPath,
    this.attachmentType,
  });

  AiChatState copyWith({
    AiChatStatus? status,
    List<AIMessage>? messages,
    AiAnimationState? animationState,
    bool? isVoiceEnabled,
    String? errorMessage,
    String? attachmentPath,
    String? attachmentType,
  }) {
    return AiChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      animationState: animationState ?? this.animationState,
      isVoiceEnabled: isVoiceEnabled ?? this.isVoiceEnabled,
      errorMessage: errorMessage ?? this.errorMessage,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      attachmentType: attachmentType ?? this.attachmentType,
    );
  }

  @override
  List<Object?> get props => [
    status,
    messages,
    animationState,
    isVoiceEnabled,
    errorMessage,
    attachmentPath,
    attachmentType,
  ];
}
