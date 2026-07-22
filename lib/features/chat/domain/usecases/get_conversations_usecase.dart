import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class GetConversationsUseCase {
  final ChatRepository repository;

  const GetConversationsUseCase({
    required this.repository,
  });

  Stream<List<Conversation>> call(
    String userId,
  ) {
    return repository.getConversations(
      userId,
    );
  }
}