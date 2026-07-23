import '../entities/media_upload_result.dart';
import '../repositories/media_repository.dart';

class UploadVideoUseCase {
  final MediaRepository repository;

  UploadVideoUseCase(this.repository);

  Future<MediaUploadResult> call({
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