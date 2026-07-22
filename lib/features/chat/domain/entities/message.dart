class Message {
  final String id;
  final String conversationId;
  final String senderId;

  // Message
  final String messageType; // text, image, video, voice, file
  final String message;

  // Media
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;

  // Status
  final String status;

  // Time
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  // Extra Features
  final String? replyToMessageId;
  final bool isEdited;
  final bool isDeleted;
  final List<String> deletedFor;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    required this.message,

    this.mediaUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,

    required this.status,

    required this.sentAt,
    this.deliveredAt,
    this.readAt,

    this.replyToMessageId,

    this.isEdited = false,
    this.isDeleted = false,
    this.deletedFor = const [],
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? messageType,
    String? message,

    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,

    String? status,

    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,

    String? replyToMessageId,

    bool? isEdited,
    bool? isDeleted,
    List<String>? deletedFor,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,

      messageType: messageType ?? this.messageType,
      message: message ?? this.message,

      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,

      status: status ?? this.status,

      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,

      replyToMessageId:
          replyToMessageId ?? this.replyToMessageId,

      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedFor: deletedFor ?? this.deletedFor,
    );
  }
}