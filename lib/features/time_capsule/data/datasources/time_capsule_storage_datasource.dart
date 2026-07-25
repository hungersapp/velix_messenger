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

  /// Deletes media/thumbnail files for a story. Missing files are ignored.
  Future<void> deleteStoryMedia({
    required String ownerId,
    required String storyId,
    String? mediaUrl,
    String? thumbnailUrl,
  });
}
