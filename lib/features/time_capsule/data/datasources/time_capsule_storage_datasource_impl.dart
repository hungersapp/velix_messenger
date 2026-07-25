import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import '../../../../core/services/firebase_storage_service.dart';
import 'time_capsule_storage_datasource.dart';

class TimeCapsuleStorageDataSourceImpl
    implements TimeCapsuleStorageDataSource {
  TimeCapsuleStorageDataSourceImpl({
    FirebaseStorageService? storageService,
    FirebaseStorage? storage,
  })  : _storageService = storageService ?? FirebaseStorageService(),
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorageService _storageService;
  final FirebaseStorage _storage;

  @override
  Future<String> uploadMedia({
    required String ownerId,
    required String storyId,
    required String localFilePath,
    required String mediaType,
  }) async {
    final file = File(localFilePath);
    final extension = path.extension(localFilePath);
    final folder = mediaType == 'video' ? 'videos' : 'images';
    final storagePath =
        'time_capsule/$ownerId/$storyId/$folder/media$extension';

    final contentType = mediaType == 'video'
        ? 'video/mp4'
        : 'image/jpeg';

    return _storageService.uploadFile(
      path: storagePath,
      file: file,
      contentType: contentType,
    );
  }

  @override
  Future<String> uploadThumbnail({
    required String ownerId,
    required String storyId,
    required String localFilePath,
  }) async {
    final file = File(localFilePath);
    final storagePath =
        'time_capsule/$ownerId/$storyId/thumbnails/thumb.jpg';

    return _storageService.uploadFile(
      path: storagePath,
      file: file,
      contentType: 'image/jpeg',
    );
  }

  @override
  Future<void> deleteStoryMedia({
    required String ownerId,
    required String storyId,
    String? mediaUrl,
    String? thumbnailUrl,
  }) async {
    await _deleteByUrl(mediaUrl);
    await _deleteByUrl(thumbnailUrl);
    await _deletePrefix(_storage.ref('time_capsule/$ownerId/$storyId'));
  }

  Future<void> _deleteByUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      return;
    }
    try {
      await _storage.refFromURL(url).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found' || e.code == 'invalid-argument') {
        return;
      }
      rethrow;
    } catch (_) {
      // Non-fatal for orphaned/invalid URLs.
    }
  }

  Future<void> _deletePrefix(Reference ref) async {
    try {
      final result = await ref.listAll();
      for (final item in result.items) {
        try {
          await item.delete();
        } on FirebaseException catch (e) {
          if (e.code != 'object-not-found') {
            rethrow;
          }
        }
      }
      for (final prefix in result.prefixes) {
        await _deletePrefix(prefix);
      }
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return;
      }
      rethrow;
    }
  }
}
