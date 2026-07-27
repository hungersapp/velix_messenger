import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/story_entity.dart';
import '../../domain/repositories/time_capsule_repository.dart';
import '../datasources/time_capsule_remote_datasource.dart';
import '../datasources/time_capsule_storage_datasource.dart';
import '../models/story_model.dart';

class TimeCapsuleRepositoryImpl implements TimeCapsuleRepository {
  const TimeCapsuleRepositoryImpl({
    required this.remoteDataSource,
    required this.storageDataSource,
  });

  final TimeCapsuleRemoteDataSource remoteDataSource;
  final TimeCapsuleStorageDataSource storageDataSource;

  @override
  Stream<List<StoryEntity>> watchActiveStories() {
    return remoteDataSource.watchActiveStories().map(
          (models) => models.map(_toEntity).toList(),
        );
  }

  @override
  Future<List<StoryEntity>> getOlderActiveStories({
    required String beforeStoryId,
    int limit = 50,
  }) async {
    final models = await remoteDataSource.getOlderActiveStories(
      beforeStoryId: beforeStoryId,
      limit: limit,
    );
    return models.map(_toEntity).toList();
  }

  @override
  Future<String> createStory(StoryEntity story) async {
    await remoteDataSource.createStory(_toModel(story));
    return story.id;
  }

  @override
  Future<void> markStorySeen({
    required String storyId,
    required String viewerId,
  }) {
    return remoteDataSource.markStorySeen(
      storyId: storyId,
      viewerId: viewerId,
    );
  }

  @override
  Future<bool> toggleStoryLike({
    required String storyId,
    required String userId,
  }) {
    return remoteDataSource.toggleStoryLike(
      storyId: storyId,
      userId: userId,
    );
  }

  @override
  Future<String> uploadMedia({
    required String ownerId,
    required String storyId,
    required String localFilePath,
    required String mediaType,
  }) {
    return storageDataSource.uploadMedia(
      ownerId: ownerId,
      storyId: storyId,
      localFilePath: localFilePath,
      mediaType: mediaType,
    );
  }

  @override
  Future<String?> uploadThumbnail({
    required String ownerId,
    required String storyId,
    required String localFilePath,
  }) async {
    return storageDataSource.uploadThumbnail(
      ownerId: ownerId,
      storyId: storyId,
      localFilePath: localFilePath,
    );
  }

  @override
  Future<void> deleteStory(StoryEntity story) async {
    try {
      await storageDataSource.deleteStoryMedia(
        ownerId: story.ownerId,
        storyId: story.id,
        mediaUrl: story.mediaUrl,
        thumbnailUrl: story.thumbnailUrl,
      );
    } catch (_) {
      // Continue so Firestore doc can still be removed.
    }

    await remoteDataSource.deleteStory(story.id);
  }

  StoryEntity _toEntity(StoryModel model) {
    return StoryEntity(
      id: model.id,
      ownerId: model.ownerId,
      mediaType: model.mediaType,
      mediaUrl: model.mediaUrl,
      thumbnailUrl: model.thumbnailUrl,
      caption: model.caption,
      createdAt: model.createdAt.toDate(),
      expiresAt: model.expiresAt.toDate(),
      seenBy: model.seenBy,
      viewers: model.viewers.map(
        (key, value) => MapEntry(key, value.toDate()),
      ),
      likes: model.likes.map(
        (key, value) => MapEntry(key, value.toDate()),
      ),
      visibility: model.visibility,
      durationMs: model.durationMs,
    );
  }

  StoryModel _toModel(StoryEntity entity) {
    return StoryModel(
      id: entity.id,
      ownerId: entity.ownerId,
      mediaType: entity.mediaType,
      mediaUrl: entity.mediaUrl,
      thumbnailUrl: entity.thumbnailUrl,
      caption: entity.caption,
      createdAt: Timestamp.fromDate(entity.createdAt),
      expiresAt: Timestamp.fromDate(entity.expiresAt),
      seenBy: entity.seenBy,
      viewers: entity.viewers.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      likes: entity.likes.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      visibility: entity.visibility,
      durationMs: entity.durationMs,
    );
  }
}
