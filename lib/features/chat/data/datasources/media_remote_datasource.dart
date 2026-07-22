abstract class MediaRemoteDataSource {
  /// Upload Image
  Future<String> uploadImage({
    required String conversationId,
    required String senderId,
    required String filePath,
  });

  /// Upload Video
  Future<String> uploadVideo({
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

  /// Delete Media (Future Support)
  Future<void> deleteMedia(String downloadUrl);
}