class Conversation {
  final String id;
  final String conversationKey;
  final List<String> participants;

  // Last Message
  final String lastMessage;
  final String lastMessageSenderId;
  final String lastMessageType;

  // Typing
  final Map<String, bool> typingStatus;

  // Unread Count
  final Map<String, int> unreadCount;

  // Read Status
  final Map<String, DateTime?> lastReadAt;

  // Group Support
  final bool isGroup;
  final String? groupName;
  final String? groupPhotoUrl;

  // Time
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
    required this.unreadCount,
    required this.lastReadAt,
    required this.isGroup,
    this.groupName,
    this.groupPhotoUrl,
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
    Map<String, int>? unreadCount,
    Map<String, DateTime?>? lastReadAt,
    bool? isGroup,
    String? groupName,
    String? groupPhotoUrl,
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
      lastMessageType:
          lastMessageType ?? this.lastMessageType,
      typingStatus:
          typingStatus ?? this.typingStatus,
      unreadCount:
          unreadCount ?? this.unreadCount,
      lastReadAt:
          lastReadAt ?? this.lastReadAt,
      isGroup:
          isGroup ?? this.isGroup,
      groupName:
          groupName ?? this.groupName,
      groupPhotoUrl:
          groupPhotoUrl ?? this.groupPhotoUrl,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
      lastMessageAt:
          lastMessageAt ?? this.lastMessageAt,
    );
  }
}