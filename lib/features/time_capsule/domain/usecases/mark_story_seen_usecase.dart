import '../repositories/time_capsule_repository.dart';

class MarkStorySeenUseCase {
  const MarkStorySeenUseCase(this._repository);

  final TimeCapsuleRepository _repository;

  Future<void> call({
    required String storyId,
    required String viewerId,
  }) {
    return _repository.markStorySeen(
      storyId: storyId,
      viewerId: viewerId,
    );
  }
}
