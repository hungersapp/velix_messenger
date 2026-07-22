class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String message;
  final String status;
  final DateTime sentAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.message,
    required this.status,
    required this.sentAt,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? message,
    String? status,
    DateTime? sentAt,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}