import 'dart:io';

import 'package:path/path.dart' as path;

import '../../../../core/services/firebase_storage_service.dart';
import 'time_capsule_storage_datasource.dart';

class TimeCapsuleStorageDataSourceImpl
    implements TimeCapsuleStorageDataSource {
  TimeCapsuleStorageDataSourceImpl({
    FirebaseStorageService? storageService,
  }) : _storageService =
            storageService ?? FirebaseStorageService();

  final FirebaseStorageService _storageService;

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
}
