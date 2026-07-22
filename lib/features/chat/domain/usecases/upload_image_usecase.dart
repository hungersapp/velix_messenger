import '../repositories/media_repository.dart';

class UploadImageUseCase {
  final MediaRepository repository;

  UploadImageUseCase(this.repository);

  Future<String> call({
    required String conversationId,
    required String senderId,
    required String filePath,
  }) {
    return repository.uploadImage(
      conversationId: conversationId,
      senderId: senderId,
      filePath: filePath,
    );
  }
}