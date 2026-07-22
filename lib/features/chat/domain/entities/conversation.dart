class Conversation {
  final String id;
  final String conversationKey;
  final List<String> participants;
  final String lastMessage;
  final String lastMessageSenderId;
  final String lastMessageType;
  final Map<String, bool> typingStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastMessageAt;

  const Conversation({
    required this.id,
    required this.conversationKey,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageType,
    required this.typingStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
  });

  Conversation copyWith({
    String? id,
    String? conversationKey,
    List<String>? participants,
    String? lastMessage,
    String? lastMessageSenderId,
    String? lastMessageType,
    Map<String, bool>? typingStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      conversationKey: conversationKey ?? this.conversationKey,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId:
          lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      typingStatus: typingStatus ?? this.typingStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}