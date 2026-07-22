import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class OpenChatUseCase {
  final ChatRepository repository;

  const OpenChatUseCase({
    required this.repository,
  });

  Future<String> call({
    required String currentUserUid,
    required String otherUserUid,
  }) async {
    // Create deterministic participants list
    final participants = <String>[
      currentUserUid,
      otherUserUid,
    ]..sort();

    // Generate unique conversation key
    final conversationKey = participants.join('_');

    // Check existing conversation
    final existingConversation =
        await repository.getConversationByKey(
      conversationKey,
    );

    if (existingConversation != null) {
      return existingConversation.id;
    }

    // Create new conversation
    final now = DateTime.now();

    final newConversation = Conversation(
  id: '',
  conversationKey: conversationKey,
  participants: participants,
  lastMessage: '',
  lastMessageSenderId: '',
  lastMessageType: '',
  typingStatus: {
    for (final user in participants) user: false,
  },
  createdAt: now,
  updatedAt: now,
  lastMessageAt: now,

  // V2 fields
  unreadCount: {
    for (final user in participants) user: 0,
  },

  lastReadAt: {
    for (final user in participants) user: null,
  },

  isGroup: false,
  groupName: null,
  groupPhotoUrl: null,
);

    return repository.createConversation(
      newConversation,
    );
  }
}