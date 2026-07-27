import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class GetOlderConversationsUseCase {
  final ChatRepository repository;

  const GetOlderConversationsUseCase({
    required this.repository,
  });

  Future<List<Conversation>> call({
    required String userId,
    required String beforeConversationId,
    int limit = 30,
  }) {
    return repository.getOlderConversations(
      userId: userId,
      beforeConversationId: beforeConversationId,
      limit: limit,
    );
  }
}
