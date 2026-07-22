import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class GetMessagesUseCase {
  final ChatRepository repository;

  const GetMessagesUseCase({
    required this.repository,
  });

  Stream<List<Message>> call(
    String conversationId,
  ) {
    return repository.getMessages(
      conversationId,
    );
  }
}