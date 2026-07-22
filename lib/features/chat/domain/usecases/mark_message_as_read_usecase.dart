import '../repositories/chat_repository.dart';

class MarkMessageAsReadUseCase {
  final ChatRepository repository;

  MarkMessageAsReadUseCase(this.repository);

  Future<void> call({
    required String conversationId,
    required String messageId,
  }) {
    return repository.markMessageAsRead(
      conversationId: conversationId,
      messageId: messageId,
    );
  }
}