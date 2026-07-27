import '../entities/story_entity.dart';
import '../repositories/time_capsule_repository.dart';

class GetOlderActiveStoriesUseCase {
  const GetOlderActiveStoriesUseCase(this._repository);

  final TimeCapsuleRepository _repository;

  Future<List<StoryEntity>> call({
    required String beforeStoryId,
    int limit = 50,
  }) {
    return _repository.getOlderActiveStories(
      beforeStoryId: beforeStoryId,
      limit: limit,
    );
  }
}
