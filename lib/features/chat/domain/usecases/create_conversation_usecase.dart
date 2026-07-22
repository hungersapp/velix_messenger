import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class CreateConversationUseCase {
  final ChatRepository repository;

  const CreateConversationUseCase({
    required this.repository,
  });

  Future<String> call(
    Conversation conversation,
  ) {
    return repository.createConversation(conversation);
  }
}