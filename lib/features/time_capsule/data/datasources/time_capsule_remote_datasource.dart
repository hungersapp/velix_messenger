import '../models/story_model.dart';

abstract class TimeCapsuleRemoteDataSource {
  Stream<List<StoryModel>> watchActiveStories();

  Future<void> createStory(StoryModel story);

  Future<void> markStorySeen({
    required String storyId,
    required String viewerId,
  });
}
