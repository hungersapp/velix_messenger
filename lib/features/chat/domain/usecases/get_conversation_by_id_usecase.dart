import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class GetConversationByIdUseCase {
  final ChatRepository repository;

  const GetConversationByIdUseCase({
    required this.repository,
  });

  Future<Conversation?> call(
    String conversationId,
  ) {
    return repository.getConversationById(
      conversationId,
    );
  }
}