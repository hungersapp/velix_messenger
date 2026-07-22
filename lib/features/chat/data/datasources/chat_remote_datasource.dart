import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  /// Create a new conversation
  Future<String> createConversation(
    ConversationModel conversation,
  );

  /// Get conversation by document id
  Future<ConversationModel?> getConversationById(
    String conversationId,
  );

  /// Get conversation using conversationKey
  Future<ConversationModel?> getConversationByKey(
    String conversationKey,
  );

  /// Watch a single conversation in realtime
  Stream<ConversationModel?> watchConversationById(
    String conversationId,
  );

  /// Get all conversations of a user
  Stream<List<ConversationModel>> getConversations(
    String userId,
  );

  /// Send a new message
  Future<void> sendMessage(
    MessageModel message,
  );

  /// Get realtime messages
  Stream<List<MessageModel>> getMessages(
    String conversationId,
  );

  /// Update conversation metadata
  Future<void> updateConversation({
    required String conversationId,
    required String lastMessage,
    required String lastMessageSenderId,
    required String lastMessageType,
  });

  /// Update typing status
  Future<void> updateTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  });

  // ===========================
  // Sprint 2.4B
  // Message Status
  // ===========================

  Future<void> updateMessageStatus({
    required String conversationId,
    required String messageId,
    required String status,
  });

  Future<void> markMessageAsDelivered({
    required String conversationId,
    required String messageId,
  });

  Future<void> markMessageAsRead({
    required String conversationId,
    required String messageId,
  });
}