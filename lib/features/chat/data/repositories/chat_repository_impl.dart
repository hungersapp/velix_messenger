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
    );
  }

  @override
  Future<Conversation?> getConversationByKey(
    String conversationKey,
  ) async {
    final model =
        await remoteDataSource.getConversationByKey(
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
                  lastMessageSenderId:
                      model.lastMessageSenderId,
                  lastMessageType:
                      model.lastMessageType,
                  typingStatus: model.typingStatus,
                  createdAt:
                      model.createdAt.toDate(),
                  updatedAt:
                      model.updatedAt.toDate(),
                  lastMessageAt:
                      model.lastMessageAt.toDate(),
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
      message: message.message,
      status: message.status,
      sentAt: Timestamp.fromDate(message.sentAt),
    );

    await remoteDataSource.sendMessage(model);
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
                  conversationId:
                      model.conversationId,
                  senderId: model.senderId,
                  message: model.message,
                  status: model.status,
                  sentAt: model.sentAt.toDate(),
                ),
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
}