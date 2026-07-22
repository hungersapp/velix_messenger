import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<String> createConversation(
    Conversation conversation,
  ) async {
    final model = ConversationModel(
      id: conversation.id,
      conversationKey: conversation.conversationKey,
      participants: conversation.participants,
      lastMessage: conversation.lastMessage,
      lastMessageSenderId: conversation.lastMessageSenderId,
      lastMessageType: conversation.lastMessageType,
      typingStatus: conversation.typingStatus,
      createdAt: Timestamp.fromDate(conversation.createdAt),
      updatedAt: Timestamp.fromDate(conversation.updatedAt),
      lastMessageAt: Timestamp.fromDate(conversation.lastMessageAt),
      unreadCount: conversation.unreadCount,
lastReadAt: conversation.lastReadAt.map(
  (key, value) => MapEntry(
    key,
    value != null ? Timestamp.fromDate(value) : null,
  ),
),
isGroup: conversation.isGroup,
groupName: conversation.groupName,
groupPhotoUrl: conversation.groupPhotoUrl,
    );

    return remoteDataSource.createConversation(model);
  }

  @override
  Future<Conversation?> getConversationById(
    String conversationId,
  ) async {
    final model =
        await remoteDataSource.getConversationById(
      conversationId,
    );

    if (model == null) return null;

    return Conversation(
  id: model.id,
  conversationKey: model.conversationKey,
  participants: model.participants,
  lastMessage: model.lastMessage,
  lastMessageSenderId: model.lastMessageSenderId,
  lastMessageType: model.lastMessageType,
  typingStatus: model.typingStatus,
  createdAt: model.createdAt.toDate(),
  updatedAt: model.updatedAt.toDate(),
  lastMessageAt: model.lastMessageAt.toDate(),
  unreadCount: model.unreadCount,
  lastReadAt: model.lastReadAt.map(
    (key, value) => MapEntry(
      key,
      value?.toDate(),
    ),
  ),
  isGroup: model.isGroup,
  groupName: model.groupName,
  groupPhotoUrl: model.groupPhotoUrl,
);
  }

 @override
Future<Conversation?> getConversationByKey(
  String conversationKey,
) async {
  final model = await remoteDataSource.getConversationByKey(
    conversationKey,
  );

    if (model == null) return null;

    return Conversation(
      id: model.id,
      conversationKey: model.conversationKey,
      participants: model.participants,
      lastMessage: model.lastMessage,
      lastMessageSenderId: model.lastMessageSenderId,
      lastMessageType: model.lastMessageType,
      typingStatus: model.typingStatus,
      createdAt: model.createdAt.toDate(),
      updatedAt: model.updatedAt.toDate(),
      lastMessageAt: model.lastMessageAt.toDate(),
      unreadCount: model.unreadCount,

lastReadAt: model.lastReadAt.map(
  (key, value) => MapEntry(
    key,
    value?.toDate(),
  ),
),

isGroup: model.isGroup,
groupName: model.groupName,
groupPhotoUrl: model.groupPhotoUrl,
    );
  }

  @override
  Stream<Conversation?> watchConversationById(
    String conversationId,
  ) {
    return remoteDataSource
        .watchConversationById(conversationId)
        .map((model) {
      if (model == null) return null;

      return Conversation(
        id: model.id,
        conversationKey: model.conversationKey,
        participants: model.participants,
        lastMessage: model.lastMessage,
        lastMessageSenderId: model.lastMessageSenderId,
        lastMessageType: model.lastMessageType,
        typingStatus: model.typingStatus,
        createdAt: model.createdAt.toDate(),
        updatedAt: model.updatedAt.toDate(),
        lastMessageAt: model.lastMessageAt.toDate(),
        unreadCount: model.unreadCount,
lastReadAt: model.lastReadAt.map(
  (key, value) => MapEntry(
    key,
    value?.toDate(),
  ),
),
isGroup: model.isGroup,
groupName: model.groupName,
groupPhotoUrl: model.groupPhotoUrl,
      );
    });
  }

  @override
Stream<List<Conversation>> getConversations(
  String userId,
) {
  return remoteDataSource.getConversations(userId).map(
    (models) => models
        .map(
          (model) => Conversation(
            id: model.id,
            conversationKey: model.conversationKey,
            participants: model.participants,
            lastMessage: model.lastMessage,
            lastMessageSenderId: model.lastMessageSenderId,
            lastMessageType: model.lastMessageType,
            typingStatus: model.typingStatus,
            createdAt: model.createdAt.toDate(),
            updatedAt: model.updatedAt.toDate(),
            lastMessageAt: model.lastMessageAt.toDate(),
            unreadCount: model.unreadCount,
            lastReadAt: model.lastReadAt.map(
              (key, value) => MapEntry(
                key,
                value?.toDate(),
              ),
            ),
            isGroup: model.isGroup,
            groupName: model.groupName,
            groupPhotoUrl: model.groupPhotoUrl,
          ),
        )
        .toList(),
  );
}

  @override
Future<void> updateConversation({
  required String conversationId,
  required String lastMessage,
  required String lastMessageSenderId,
  required String lastMessageType,
}) {
  return remoteDataSource.updateConversation(
    conversationId: conversationId,
    lastMessage: lastMessage,
    lastMessageSenderId: lastMessageSenderId,
    lastMessageType: lastMessageType,
  );
}

  @override
  Future<void> sendMessage(
    Message message,
  ) async {
    final model = MessageModel(
  id: message.id,
  conversationId: message.conversationId,
  senderId: message.senderId,
  messageType: message.messageType,
  message: message.message,
  mediaUrl: message.mediaUrl,
  thumbnailUrl: message.thumbnailUrl,
  fileName: message.fileName,
  fileSize: message.fileSize,
  mimeType: message.mimeType,
  status: message.status,
  sentAt: Timestamp.fromDate(message.sentAt),
  deliveredAt: message.deliveredAt != null
      ? Timestamp.fromDate(message.deliveredAt!)
      : null,
  readAt: message.readAt != null
      ? Timestamp.fromDate(message.readAt!)
      : null,
  replyToMessageId: message.replyToMessageId,
  isEdited: message.isEdited,
  isDeleted: message.isDeleted,
  deletedFor: message.deletedFor,
);

    await remoteDataSource.sendMessage(model);

    await remoteDataSource.updateConversation(
    conversationId: message.conversationId,
    lastMessage: message.message,
    lastMessageSenderId: message.senderId,
    lastMessageType: message.messageType,// அல்லது model.messageType
  );

  }

  @override
  Stream<List<Message>> getMessages(
    String conversationId,
  ) {
    return remoteDataSource.getMessages(conversationId).map(
          (models) => models
              .map(
                (model) => Message(
  id: model.id,
  conversationId: model.conversationId,
  senderId: model.senderId,
  messageType: model.messageType,
  message: model.message,
  mediaUrl: model.mediaUrl,
  thumbnailUrl: model.thumbnailUrl,
  fileName: model.fileName,
  fileSize: model.fileSize,
  mimeType: model.mimeType,
  status: model.status,
  sentAt: model.sentAt.toDate(),
  deliveredAt: model.deliveredAt?.toDate(),
  readAt: model.readAt?.toDate(),
  replyToMessageId: model.replyToMessageId,
  isEdited: model.isEdited,
  isDeleted: model.isDeleted,
  deletedFor: model.deletedFor,
)
              )
              .toList(),
        );
  }

  @override
  Future<void> updateTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) {
    return remoteDataSource.updateTypingStatus(
      conversationId: conversationId,
      userId: userId,
      isTyping: isTyping,
    );
  }
  @override
Future<void> updateMessageStatus({
  required String conversationId,
  required String messageId,
  required String status,
}) {
  return remoteDataSource.updateMessageStatus(
    conversationId: conversationId,
    messageId: messageId,
    status: status,
  );
}

@override
Future<void> markMessageAsDelivered({
  required String conversationId,
  required String messageId,
}) {
  return remoteDataSource.markMessageAsDelivered(
    conversationId: conversationId,
    messageId: messageId,
  );
}

@override
Future<void> markMessageAsRead({
  required String conversationId,
  required String messageId,
}) {
  return remoteDataSource.markMessageAsRead(
    conversationId: conversationId,
    messageId: messageId,
  );
}
}