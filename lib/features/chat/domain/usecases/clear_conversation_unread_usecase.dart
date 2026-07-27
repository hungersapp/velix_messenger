import '../repositories/chat_repository.dart';

class ClearConversationUnreadUseCase {
  final ChatRepository repository;

  const ClearConversationUnreadUseCase({
    required this.repository,
  });

  Future<void> call({
    required String conversationId,
    required String userId,
  }) {
    return repository.clearConversationUnread(
      conversationId: conversationId,
      userId: userId,
    );
  }
}
