import '../repositories/chat_repository.dart';

class UpdateMessageStatusUseCase {
  final ChatRepository repository;

  UpdateMessageStatusUseCase(this.repository);

  Future<void> call({
    required String conversationId,
    required String messageId,
    required String status,
  }) {
    return repository.updateMessageStatus(
      conversationId: conversationId,
      messageId: messageId,
      status: status,
    );
  }
}