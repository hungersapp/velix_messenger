import '../repositories/media_repository.dart';

class UploadVideoUseCase {
  final MediaRepository repository;

  UploadVideoUseCase(this.repository);

  Future<String> call({
    required String conversationId,
    required String senderId,
    required String filePath,
  }) {
    return repository.uploadVideo(
      conversationId: conversationId,
      senderId: senderId,
      filePath: filePath,
    );
  }
}