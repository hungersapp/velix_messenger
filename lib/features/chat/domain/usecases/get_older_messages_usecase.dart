import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class GetOlderMessagesUseCase {
  final ChatRepository repository;

  const GetOlderMessagesUseCase({
    required this.repository,
  });

  Future<List<Message>> call({
    required String conversationId,
    required String beforeMessageId,
    int limit = 50,
  }) {
    return repository.getOlderMessages(
      conversationId: conversationId,
      beforeMessageId: beforeMessageId,
      limit: limit,
    );
  }
}
