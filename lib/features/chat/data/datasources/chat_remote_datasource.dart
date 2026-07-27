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

  /// Get realtime conversations (latest page only)
  Stream<List<ConversationModel>> getConversations(
    String userId,
  );

  /// Older conversations after [beforeConversationId] (cursor-based, one page).
  Future<List<ConversationModel>> getOlderConversations({
    required String userId,
    required String beforeConversationId,
    int limit = 30,
  });

  /// Send a new message
  Future<void> sendMessage(
    MessageModel message,
  );

  /// Get realtime messages (latest page only)
  Stream<List<MessageModel>> getMessages(
    String conversationId,
  );

  /// Older messages before [beforeMessageId] (cursor-based, one page).
  Future<List<MessageModel>> getOlderMessages({
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