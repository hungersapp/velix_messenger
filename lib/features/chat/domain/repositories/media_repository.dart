import '../entities/media_upload_result.dart';

abstract class MediaRepository {
  /// Upload Image
  Future<String> uploadImage({
    required String conversationId,
    required String senderId,
    required String filePath,
  });

  /// Upload Video
  Future<MediaUploadResult> uploadVideo({
    required String conversationId,
    required String senderId,
    required String filePath,
  });

  /// Upload File
  Future<String> uploadFile({
    required String conversationId,
    required String senderId,
    required String filePath,
    required String fileName,
  });
}