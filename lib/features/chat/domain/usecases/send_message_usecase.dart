import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  const SendMessageUseCase({
    required this.repository,
  });

  Future<void> call(
    Message message,
  ) {
    return repository.sendMessage(
      message,
    );
  }
}