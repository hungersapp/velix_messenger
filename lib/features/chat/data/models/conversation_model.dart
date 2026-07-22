import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String conversationKey;
  final List<String> participants;
  final String lastMessage;
  final String lastMessageSenderId;
  final String lastMessageType;
  final Map<String, bool> typingStatus;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Timestamp lastMessageAt;

  const ConversationModel({
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

  factory ConversationModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return ConversationModel(
      id: documentId,
      conversationKey: map['conversationKey'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageType: map['lastMessageType'] ?? '',
      typingStatus: Map<String, bool>.from(
        map['typingStatus'] ?? {},
      ),
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: map['updatedAt'] as Timestamp? ?? Timestamp.now(),
      lastMessageAt:
          map['lastMessageAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationKey': conversationKey,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageType': lastMessageType,
      'typingStatus': typingStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastMessageAt': lastMessageAt,
    };
  }

  ConversationModel copyWith({
    String? id,
    String? conversationKey,
    List<String>? participants,
    String? lastMessage,
    String? lastMessageSenderId,
    String? lastMessageType,
    Map<String, bool>? typingStatus,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? lastMessageAt,
  }) {
    return ConversationModel(
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