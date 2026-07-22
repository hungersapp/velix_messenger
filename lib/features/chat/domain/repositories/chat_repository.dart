import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  /// Create a new conversation
  Future<String> createConversation(
    Conversation conversation,
  );

  /// Get conversation by document id
  Future<Conversation?> getConversationById(
    String conversationId,
  );

  /// Get conversation using conversationKey
  Future<Conversation?> getConversationByKey(
    String conversationKey,
  );

  /// Watch conversation in realtime
  Stream<Conversation?> watchConversationById(
    String conversationId,
  );

  /// Get all conversations of a user
  Stream<List<Conversation>> getConversations(
    String userId,
  );

  /// Send a message
  Future<void> sendMessage(
    Message message,
  );

  /// Get realtime messages
  Stream<List<Message>> getMessages(
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