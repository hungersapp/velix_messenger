import '../repositories/time_capsule_repository.dart';

class ToggleStoryLikeUseCase {
  const ToggleStoryLikeUseCase(this._repository);

  final TimeCapsuleRepository _repository;

  /// Returns `true` if the user likes the story after the toggle.
  Future<bool> call({
    required String storyId,
    required String userId,
  }) {
    return _repository.toggleStoryLike(
      storyId: storyId,
      userId: userId,
    );
  }
}
