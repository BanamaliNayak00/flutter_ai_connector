import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../domain/entities/ai_config.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/datasources/langchain_data_source.dart';
import '../bloc/ai_chat_bloc.dart';
import '../bloc/ai_chat_event.dart';
import '../bloc/ai_chat_state.dart';
import 'chat_bubble.dart';

class AIAssistantView extends StatelessWidget {
  final AIConfig config;
  final String? customLottiePath;

  const AIAssistantView({
    super.key,
    required this.config,
    this.customLottiePath,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AIRepositoryImpl(dataSource: LangChainDataSource()),
      child: BlocProvider(
        create: (context) =>
            AiChatBloc(repository: context.read<AIRepositoryImpl>())
              ..add(ApiKeyChanged(config)),
        child: _AIAssistantViewContent(
          config: config,
          customLottiePath: customLottiePath,
        ),
      ),
    );
  }
}

class _AIAssistantViewContent extends StatefulWidget {
  final AIConfig config;
  final String? customLottiePath;

  const _AIAssistantViewContent({required this.config, this.customLottiePath});

  @override
  State<_AIAssistantViewContent> createState() =>
      _AIAssistantViewContentState();
}

class _AIAssistantViewContentState extends State<_AIAssistantViewContent> {
  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      await _speechToText.initialize();
    } catch (e) {
      // Handle initialization error silently or log to analytics
    }
  }

  void _startListening() async {
    if (!_isListening) {
      var available = _speechToText.isAvailable;
      if (!available) {
        try {
          available = await _speechToText.initialize();
        } catch (e) {
          // Handle error
        }
      }
      if (available) {
        if (!mounted) return;
        setState(() => _isListening = true);
        if (!context.mounted) return;
        context.read<AiChatBloc>().add(
          const UpdateAnimation(AiAnimationState.listening),
        );
        _speechToText.listen(
          pauseFor: const Duration(seconds: 3),
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
            if (result.finalResult) {
              setState(() => _isListening = false);
              if (result.recognizedWords.isNotEmpty) {
                context.read<AiChatBloc>().add(
                  VoiceInput(result.recognizedWords),
                );
                _textController.clear();
              } else {
                context.read<AiChatBloc>().add(
                  const UpdateAnimation(AiAnimationState.idle),
                );
              }
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
      if (!context.mounted) return;
      context.read<AiChatBloc>().add(
        const UpdateAnimation(AiAnimationState.idle),
      );
    }
  }

  void _sendMessage() {
    if (_textController.text.isNotEmpty) {
      context.read<AiChatBloc>().add(SendMessage(_textController.text));
      _textController.clear();
    }
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () async {
              Navigator.pop(ctx);
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: ImageSource.camera);
              if (picked != null && context.mounted) {
                context.read<AiChatBloc>().add(
                  AttachmentSelected(picked.path, 'image'),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Gallery'),
            onTap: () async {
              Navigator.pop(ctx);
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (picked != null && context.mounted) {
                context.read<AiChatBloc>().add(
                  AttachmentSelected(picked.path, 'image'),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: const Text('File'),
            onTap: () async {
              Navigator.pop(ctx);
              final result = await FilePicker.platform.pickFiles();
              if (result != null &&
                  result.files.single.path != null &&
                  context.mounted) {
                context.read<AiChatBloc>().add(
                  AttachmentSelected(result.files.single.path!, 'file'),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF000000),
            Color(0xFF1A0B2E),
            Color(0xFF10002B),
          ], // Black to Deep Purple
        ),
      ),
      child: Column(
        children: [
          // Top Bar - Removed speaker as requested.
          // Padding for status bar if needed.
          // We need space for the Lottie animation below the AppBar.
          const SizedBox(height: 100),

          // Animation
          SizedBox(
            height: 180,
            child: BlocBuilder<AiChatBloc, AiChatState>(
              builder: (context, state) {
                String lottieFile;
                switch (state.animationState) {
                  case AiAnimationState.listening:
                    lottieFile =
                        'packages/ai_assistant_connector/assets/ai_listening.json';
                    break;
                  case AiAnimationState.thinking:
                    lottieFile =
                        'packages/ai_assistant_connector/assets/ai_thinking.json';
                    break;
                  case AiAnimationState.speaking:
                    lottieFile =
                        'packages/ai_assistant_connector/assets/ai_speaking.json';
                    break;
                  case AiAnimationState.idle:
                    lottieFile =
                        'packages/ai_assistant_connector/assets/ai_idle.json';
                    break;
                }

                return Hero(
                  tag: 'ai_avatar',
                  child: Lottie.asset(
                    widget.customLottiePath ?? lottieFile,
                    animate: state.animationState != AiAnimationState.idle,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        border: Border.all(color: Colors.deepPurple, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        size: 80,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Chat List
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF050505), // Very dark grey/black
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurpleAccent,
                    blurRadius: 2,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: BlocBuilder<AiChatBloc, AiChatState>(
                builder: (context, state) {
                  if (state.messages.isEmpty) {
                    return const Center(
                      child: Text(
                        "Say something...",
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(message: state.messages[index]);
                    },
                  );
                },
              ),
            ),
          ),

          // Input Area
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF050505), // Match chat list bg
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attachment Preview
          BlocBuilder<AiChatBloc, AiChatState>(
            builder: (context, state) {
              if (state.attachmentPath != null &&
                  state.attachmentPath!.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurple),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.attachmentType == 'image'
                            ? Icons.image
                            : Icons.attach_file,
                        color: Colors.deepPurpleAccent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.attachmentPath!.split('/').last,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () {
                          context.read<AiChatBloc>().add(
                            const AttachmentSelected('', ''),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Input Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                if (widget.config.isMultimodal)
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.white54),
                    onPressed: () => _showAttachmentOptions(context),
                  ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.deepPurpleAccent,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                GestureDetector(
                  onTap: _startListening,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? Colors.redAccent
                          : Colors.deepPurple,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BlocBuilder<AiChatBloc, AiChatState>(
                  builder: (context, state) {
                    if (state.animationState == AiAnimationState.speaking) {
                      return GestureDetector(
                        onTap: () {
                          context.read<AiChatBloc>().add(const StopTts());
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.deepOrangeAccent,
                          ),
                          child: const Icon(
                            Icons.stop,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      );
                    }
                    if (!_isListening) {
                      return GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueAccent,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
