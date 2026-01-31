class AIMessage {
  bool get isBot => !isUser;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? attachmentPath; // Local path to file/image
  final String? attachmentType; // 'image', 'file', etc.

  const AIMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.attachmentPath,
    this.attachmentType,
  });

  factory AIMessage.user(
    String content, {
    String? attachmentPath,
    String? attachmentType,
  }) {
    return AIMessage(
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      attachmentPath: attachmentPath,
      attachmentType: attachmentType,
    );
  }

  factory AIMessage.assistant(String content) {
    return AIMessage(
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}
