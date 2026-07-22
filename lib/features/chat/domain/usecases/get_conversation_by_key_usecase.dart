import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class GetConversationByKeyUseCase {
  final ChatRepository repository;

  const GetConversationByKeyUseCase({
    required this.repository,
  });

  Future<Conversation?> call(
    String conversationKey,
  ) {
    return repository.getConversationByKey(
      conversationKey,
    );
  }
}