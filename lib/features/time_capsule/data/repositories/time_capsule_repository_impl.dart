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
      visibility: entity.visibility,
      durationMs: entity.durationMs,
    );
  }
}
