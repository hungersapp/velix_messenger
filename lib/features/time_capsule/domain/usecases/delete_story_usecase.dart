import '../entities/story_entity.dart';
import '../repositories/time_capsule_repository.dart';

class DeleteStoryUseCase {
  const DeleteStoryUseCase(this._repository);

  final TimeCapsuleRepository _repository;

  Future<void> call({
    required StoryEntity story,
    required String requesterId,
  }) {
    if (story.ownerId != requesterId) {
      throw StateError('Only the story owner can delete this Time Capsule.');
    }

    return _repository.deleteStory(story);
  }
}
