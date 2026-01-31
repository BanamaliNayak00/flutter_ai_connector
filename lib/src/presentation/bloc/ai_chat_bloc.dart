import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/entities/ai_config.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/repositories/ai_repository.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';

class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  final AIRepository _repository;
  final FlutterTts _flutterTts = FlutterTts();

  StreamSubscription? _subscription;
  String _currentAccumulatedResponse = "";
  AIConfig? _config;

  AiChatBloc({required AIRepository repository})
    : _repository = repository,
      super(const AiChatState()) {
    on<ApiKeyChanged>(_onApiKeyChanged);
    on<SendMessage>(_onSendMessage);
    on<ChunkReceived>(_onChunkReceived);
    on<GenerationCompleted>(_onGenerationCompleted);
    on<GenerationFailed>(_onGenerationFailed);
    on<SpeakMessage>((event, emit) async {
      await _flutterTts.speak(event.content);
      emit(state.copyWith(animationState: AiAnimationState.speaking));
    });

    on<ToggleVoice>(_onToggleVoice);

    on<VoiceInput>((event, emit) {
      if (!state.isVoiceEnabled) {
        emit(state.copyWith(isVoiceEnabled: true));
      }
      add(SendMessage(event.text));
    });

    on<UpdateAnimation>(_onUpdateAnimation);
    on<AttachmentSelected>(_onAttachmentSelected);

    _initTts();
    on<StopTts>((event, emit) async {
      debugPrint("Bloc: StopTts triggered");
      await _subscription?.cancel();
      await _flutterTts.stop();
      emit(state.copyWith(animationState: AiAnimationState.idle));
    });
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    // User requested "better voice". Slowing down slightly for clarity or using default.
    // Setting speech rate. 0.5 is standard, 1.0 is fast on some engines. Sticking to 0.5.
    await _flutterTts.setSpeechRate(0.5);

    _flutterTts.setCompletionHandler(() {
      add(const UpdateAnimation(AiAnimationState.idle));
    });
  }

  void _onApiKeyChanged(ApiKeyChanged event, Emitter<AiChatState> emit) {
    _config = event.config;
  }

  void _onToggleVoice(ToggleVoice event, Emitter<AiChatState> emit) async {
    await _flutterTts.setVolume(state.isVoiceEnabled ? 0 : 1);
    if (state.isVoiceEnabled) {
      await _flutterTts.stop();
    }
    emit(state.copyWith(isVoiceEnabled: !state.isVoiceEnabled));
  }

  void _onUpdateAnimation(UpdateAnimation event, Emitter<AiChatState> emit) {
    emit(state.copyWith(animationState: event.state));
  }

  void _onAttachmentSelected(
    AttachmentSelected event,
    Emitter<AiChatState> emit,
  ) {
    emit(
      state.copyWith(attachmentPath: event.path, attachmentType: event.type),
    );
  }

  void _onSendMessage(SendMessage event, Emitter<AiChatState> emit) async {
    debugPrint("Bloc: Received SendMessage event: ${event.content}");
    // Cancel any existing generation
    await _subscription?.cancel();
    _currentAccumulatedResponse = "";

    if (_config == null) {
      debugPrint("Bloc Error: Config is null");
      emit(
        state.copyWith(
          status: AiChatStatus.failure,
          errorMessage: "Configuration not set",
        ),
      );
      return;
    }

    // Include attachment if present
    final currentAttachmentPath = state.attachmentPath;
    final currentAttachmentType = state.attachmentType;

    final userMessage = AIMessage.user(
      event.content,
      attachmentPath: currentAttachmentPath,
      attachmentType: currentAttachmentType,
    );

    emit(
      state.copyWith(
        status: AiChatStatus.loading,
        messages: List.from(state.messages)..add(userMessage),
        animationState:
            AiAnimationState.thinking, // Changed to thinking for initial state
        attachmentPath: null, // Clear attachment from state after sending
        attachmentType: null,
      ),
    );

    try {
      debugPrint("Bloc: Starting Stream...");
      // For now, assuming text-only stream for simplicity unless attachment is handled by repo
      final stream = _repository.streamResponse(event.content, _config!);

      _subscription = stream.listen(
        (chunk) {
          add(ChunkReceived(chunk));
        },
        onError: (error) {
          add(GenerationFailed(error.toString()));
        },
        onDone: () {
          add(GenerationCompleted(_currentAccumulatedResponse));
        },
      );
    } catch (e) {
      add(GenerationFailed(e.toString()));
    }
  }

  void _onChunkReceived(ChunkReceived event, Emitter<AiChatState> emit) {
    _currentAccumulatedResponse += event.chunk;

    final messages = List<AIMessage>.from(state.messages);
    if (messages.isNotEmpty && messages.last.isBot) {
      messages.last = AIMessage.assistant(_currentAccumulatedResponse);
    } else {
      messages.add(AIMessage.assistant(_currentAccumulatedResponse));
    }

    emit(
      state.copyWith(
        status: AiChatStatus.success,
        messages: messages,
        animationState: state.isVoiceEnabled
            ? AiAnimationState.speaking
            : AiAnimationState.idle,
      ),
    );
  }

  void _onGenerationCompleted(
    GenerationCompleted event,
    Emitter<AiChatState> emit,
  ) async {
    debugPrint("Generation Completed.");
    // Auto-speak disabled per user request. Use manual SpeakMessage.

    // Keep state as success/idle?
    // If speaking (manual), animationState is speaking. TTS completion handler sets it to idle.
  }

  void _onGenerationFailed(GenerationFailed event, Emitter<AiChatState> emit) {
    debugPrint("Generation Failed: ${event.error}");
    emit(
      state.copyWith(
        status: AiChatStatus.failure,
        errorMessage: event.error,
        animationState: AiAnimationState.idle,
      ),
    );
  }
}
