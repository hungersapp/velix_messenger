import '../repositories/chat_repository.dart';

class UpdateConversationUseCase {
  final ChatRepository repository;

  const UpdateConversationUseCase({
    required this.repository,
  });

  Future<void> call({
    required String conversationId,
    required String lastMessage,
    required String lastMessageSenderId,
    required String lastMessageType,
  }) {
    return repository.updateConversation(
      conversationId: conversationId,
      lastMessage: lastMessage,
      lastMessageSenderId: lastMessageSenderId,
      lastMessageType: lastMessageType,
    );
  }
}