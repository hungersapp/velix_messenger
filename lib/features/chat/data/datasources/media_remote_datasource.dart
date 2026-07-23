import '../../domain/entities/media_upload_result.dart';

abstract class MediaRemoteDataSource {
  Future<String> uploadImage({
    required String conversationId,
    required String senderId,
    required String filePath,
  });

  Future<MediaUploadResult> uploadVideo({
    required String conversationId,
    required String senderId,
    required String filePath,
  });

  Future<String> uploadFile({
    required String conversationId,
    required String senderId,
    required String filePath,
    required String fileName,
  });

  Future<void> deleteMedia(String downloadUrl);
}