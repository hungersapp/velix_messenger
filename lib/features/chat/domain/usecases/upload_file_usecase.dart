import '../repositories/media_repository.dart';

class UploadFileUseCase {
  final MediaRepository repository;

  UploadFileUseCase(this.repository);

  Future<String> call({
    required String conversationId,
    required String senderId,
    required String filePath,
    required String fileName,
  }) {
    return repository.uploadFile(
      conversationId: conversationId,
      senderId: senderId,
      filePath: filePath,
      fileName: fileName,
    );
  }
}