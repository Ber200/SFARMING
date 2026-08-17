/// A single exchange in the AI assistant conversation.
///
/// [role] is `'user'` or `'assistant'`. When [isError] is true, [text] holds
/// a localization key (e.g. `ai_error`) that the UI translates.
class AiMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  final DateTime timestamp;
  final bool isError;

  const AiMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    this.isError = false,
  });

  bool get isUser => role == 'user';

  factory AiMessage.fromMap(Map<String, dynamic> map) {
    return AiMessage(
      role: map['role'] ?? 'assistant',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      isError: map['isError'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isError': isError,
    };
  }
}
