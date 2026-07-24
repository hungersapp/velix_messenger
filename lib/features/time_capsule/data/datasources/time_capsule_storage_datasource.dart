abstract class TimeCapsuleStorageDataSource {
  Future<String> uploadMedia({
    required String ownerId,
    required String storyId,
    required String localFilePath,
    required String mediaType,
  });

  Future<String> uploadThumbnail({
    required String ownerId,
    required String storyId,
    required String localFilePath,
  });
}
