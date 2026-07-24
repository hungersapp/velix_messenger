import '../entities/story_entity.dart';
import '../repositories/time_capsule_repository.dart';

class CreateStoryUseCase {
  const CreateStoryUseCase(this._repository);

  final TimeCapsuleRepository _repository;

  static const int defaultImageDurationMs = 5000;
  static const Duration expiryDuration = Duration(hours: 24);

  Future<String> call({
    required String ownerId,
    required String mediaType,
    required String localFilePath,
    String? thumbnailPath,
    String? caption,
    required int durationMs,
  }) async {
    final now = DateTime.now();
    final storyId = now.microsecondsSinceEpoch.toString();

    final mediaUrl = await _repository.uploadMedia(
      ownerId: ownerId,
      storyId: storyId,
      localFilePath: localFilePath,
      mediaType: mediaType,
    );

    String? thumbnailUrl;
    if (thumbnailPath != null) {
      thumbnailUrl = await _repository.uploadThumbnail(
        ownerId: ownerId,
        storyId: storyId,
        localFilePath: thumbnailPath,
      );
    }

    final story = StoryEntity(
      id: storyId,
      ownerId: ownerId,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      createdAt: now,
      expiresAt: now.add(expiryDuration),
      seenBy: const [],
      visibility: 'friends',
      durationMs: durationMs,
    );

    return _repository.createStory(story);
  }
}
