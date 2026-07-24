import '../entities/story_entity.dart';
import '../repositories/time_capsule_repository.dart';

class WatchActiveStoriesUseCase {
  const WatchActiveStoriesUseCase(this._repository);

  final TimeCapsuleRepository _repository;

  Stream<List<StoryEntity>> call() {
    return _repository.watchActiveStories();
  }
}
