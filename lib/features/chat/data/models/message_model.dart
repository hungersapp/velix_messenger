import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String message;
  final String status;
  final Timestamp sentAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.message,
    required this.status,
    required this.sentAt,
  });

  factory MessageModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return MessageModel(
      id: documentId,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'sent',
      sentAt: map['sentAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'message': message,
      'status': status,
      'sentAt': sentAt,
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? message,
    String? status,
    Timestamp? sentAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}