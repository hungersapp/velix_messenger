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

  /// Get realtime conversations (latest page only)
  Stream<List<Conversation>> getConversations(
    String userId,
  );

  /// Older conversations after [beforeConversationId] (cursor-based, one page).
  Future<List<Conversation>> getOlderConversations({
    required String userId,
    required String beforeConversationId,
    int limit = 30,
  });

  /// Send a message
  Future<void> sendMessage(
    Message message,
  );

  /// Get realtime messages (latest page only)
  Stream<List<Message>> getMessages(
    String conversationId,
  );

  /// Older messages before [beforeMessageId] (cursor-based, one page).
  Future<List<Message>> getOlderMessages({
    required String conversationId,
    required String beforeMessageId,
    int limit = 50,
  });

  /// Update conversation metadata (last message + unread increments for others)
  Future<void> updateConversation({
    required String conversationId,
    required String lastMessage,
    required String lastMessageSenderId,
    required String lastMessageType,
  });

  /// Clears the conversation-level unread badge for [userId] (one write).
  Future<void> clearConversationUnread({
    required String conversationId,
    required String userId,
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