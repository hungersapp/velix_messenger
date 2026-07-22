import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
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
  final String status; // sending, sent, delivered, read

  // Time
  final Timestamp sentAt;
  final Timestamp? deliveredAt;
  final Timestamp? readAt;

  // Extra Features
  final String? replyToMessageId;
  final bool isEdited;
  final bool isDeleted;
  final List<String> deletedFor;

  const MessageModel({
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

  factory MessageModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return MessageModel(
      id: documentId,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      messageType: map['messageType'] ?? 'text',
      message: map['message'] ?? '',
      mediaUrl: map['mediaUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      mimeType: map['mimeType'],
      status: map['status'] ?? 'sending',
      sentAt: map['sentAt'] as Timestamp? ?? Timestamp.now(),
      deliveredAt: map['deliveredAt'] as Timestamp?,
      readAt: map['readAt'] as Timestamp?,
      replyToMessageId: map['replyToMessageId'],
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'messageType': messageType,
      'message': message,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'status': status,
      'sentAt': sentAt,
      'deliveredAt': deliveredAt,
      'readAt': readAt,
      'replyToMessageId': replyToMessageId,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'deletedFor': deletedFor,
    };
  }

  MessageModel copyWith({
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
    Timestamp? sentAt,
    Timestamp? deliveredAt,
    Timestamp? readAt,
    String? replyToMessageId,
    bool? isEdited,
    bool? isDeleted,
    List<String>? deletedFor,
  }) {
    return MessageModel(
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
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedFor: deletedFor ?? this.deletedFor,
    );
  }
}