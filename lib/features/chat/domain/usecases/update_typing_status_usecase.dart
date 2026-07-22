import '../repositories/chat_repository.dart';

class UpdateTypingStatusUseCase {
  final ChatRepository repository;

  const UpdateTypingStatusUseCase({
    required this.repository,
  });

  Future<void> call({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) {
    return repository.updateTypingStatus(
      conversationId: conversationId,
      userId: userId,
      isTyping: isTyping,
    );
  }
}