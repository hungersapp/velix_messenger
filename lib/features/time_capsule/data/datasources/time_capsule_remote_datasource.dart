import '../models/story_model.dart';

abstract class TimeCapsuleRemoteDataSource {
  /// Realtime latest page of active capsules (expiresAt > now).
  Stream<List<StoryModel>> watchActiveStories();

  /// Older active capsules after [beforeStoryId] (cursor-based, one page).
  Future<List<StoryModel>> getOlderActiveStories({
    required String beforeStoryId,
    int limit = 50,
  });

  Future<void> createStory(StoryModel story);

  Future<void> markStorySeen({
    required String storyId,
    required String viewerId,
  });

  /// Toggles like for [userId]. Returns whether the story is liked afterwards.
  Future<bool> toggleStoryLike({
    required String storyId,
    required String userId,
  });

  Future<void> deleteStory(String storyId);
}
