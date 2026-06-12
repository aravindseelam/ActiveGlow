/// Represents a single chat message in the UI.
class MessageModel {
  final String id;
  final String text;
  final MessageRole role;
  final DateTime timestamp;
  final bool isLoading; // true while waiting for API response

  const MessageModel({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
    this.isLoading = false,
  });

  bool get isUser => role == MessageRole.user;
  bool get isBot  => role == MessageRole.bot;

  MessageModel copyWith({
    String? id,
    String? text,
    MessageRole? role,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return MessageModel(
      id:        id        ?? this.id,
      text:      text      ?? this.text,
      role:      role      ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() =>
      'MessageModel(role: $role, text: ${text.substring(0, text.length.clamp(0, 40))}…)';
}

enum MessageRole { user, bot }
