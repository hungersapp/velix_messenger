import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class WatchConversationByIdUseCase {
  final ChatRepository repository;

  const WatchConversationByIdUseCase({
    required this.repository,
  });

  Stream<Conversation?> call(
    String conversationId,
  ) {
    return repository.watchConversationById(
      conversationId,
    );
  }
}