import '../entities/story_entity.dart';

abstract class TimeCapsuleRepository {
  Stream<List<StoryEntity>> watchActiveStories();

  Future<List<StoryEntity>> getOlderActiveStories({
    required String beforeStoryId,
    int limit = 50,
  });

  Future<String> createStory(StoryEntity story);

  Future<void> markStorySeen({
    required String storyId,
    required String viewerId,
  });

  /// Toggles like for [userId]. Returns whether the story is liked afterwards.
  Future<bool> toggleStoryLike({
    required String storyId,
    required String userId,
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

  Future<void> deleteStory(StoryEntity story);
}
