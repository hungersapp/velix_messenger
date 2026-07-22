import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
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
  final Map<String, Timestamp?> lastReadAt;

  // Group Support
  final bool isGroup;
  final String? groupName;
  final String? groupPhotoUrl;

  // Timestamps
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
    required this.unreadCount,
    required this.lastReadAt,
    required this.isGroup,
    this.groupName,
    this.groupPhotoUrl,
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
      participants:
          List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId:
          map['lastMessageSenderId'] ?? '',
      lastMessageType:
          map['lastMessageType'] ?? 'text',

      typingStatus: Map<String, bool>.from(
        map['typingStatus'] ?? {},
      ),

      unreadCount: Map<String, int>.from(
        map['unreadCount'] ?? {},
      ),

      lastReadAt: (map['lastReadAt'] as Map<String, dynamic>? ?? {})
          .map(
        (key, value) => MapEntry(
          key,
          value as Timestamp?,
        ),
      ),

      isGroup: map['isGroup'] ?? false,
      groupName: map['groupName'],
      groupPhotoUrl: map['groupPhotoUrl'],

      createdAt:
          map['createdAt'] as Timestamp? ??
              Timestamp.now(),

      updatedAt:
          map['updatedAt'] as Timestamp? ??
              Timestamp.now(),

      lastMessageAt:
          map['lastMessageAt'] as Timestamp? ??
              Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationKey': conversationKey,
      'participants': participants,

      'lastMessage': lastMessage,
      'lastMessageSenderId':
          lastMessageSenderId,
      'lastMessageType':
          lastMessageType,

      'typingStatus': typingStatus,

      'unreadCount': unreadCount,

      'lastReadAt': lastReadAt,

      'isGroup': isGroup,
      'groupName': groupName,
      'groupPhotoUrl': groupPhotoUrl,

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
    Map<String, int>? unreadCount,
    Map<String, Timestamp?>? lastReadAt,
    bool? isGroup,
    String? groupName,
    String? groupPhotoUrl,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? lastMessageAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      conversationKey:
          conversationKey ??
              this.conversationKey,
      participants:
          participants ?? this.participants,
      lastMessage:
          lastMessage ?? this.lastMessage,
      lastMessageSenderId:
          lastMessageSenderId ??
              this.lastMessageSenderId,
      lastMessageType:
          lastMessageType ??
              this.lastMessageType,
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
          lastMessageAt ??
              this.lastMessageAt,
    );
  }
}