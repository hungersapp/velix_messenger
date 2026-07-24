import '../entities/story_entity.dart';

abstract class TimeCapsuleRepository {
  Stream<List<StoryEntity>> watchActiveStories();

  Future<String> createStory(StoryEntity story);

  Future<void> markStorySeen({
    required String storyId,
    required String viewerId,
  });

  Future<String> uploadMedia({
    required String ownerId,
    required String storyId,
    required String localFilePath,
    required String mediaType,
  });

  Future<String?> uploadThumbnail({
    required String ownerId,
    required String storyId,
    required String localFilePath,
  });
}
