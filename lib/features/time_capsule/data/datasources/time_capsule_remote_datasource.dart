import '../models/story_model.dart';

abstract class TimeCapsuleRemoteDataSource {
  Stream<List<StoryModel>> watchActiveStories();

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
