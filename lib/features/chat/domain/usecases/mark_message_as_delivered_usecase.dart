import '../repositories/chat_repository.dart';

class MarkMessageAsDeliveredUseCase {
  final ChatRepository repository;

  MarkMessageAsDeliveredUseCase(this.repository);

  Future<void> call({
    required String conversationId,
    required String messageId,
  }) {
    return repository.markMessageAsDelivered(
      conversationId: conversationId,
      messageId: messageId,
    );
  }
}