import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

import '../../../../core/services/native_thumbnail_service.dart';
import '../../domain/entities/media_upload_result.dart';

import 'media_remote_datasource.dart';

class MediaRemoteDataSourceImpl
    implements MediaRemoteDataSource {
  final FirebaseStorage storage;

  MediaRemoteDataSourceImpl(this.storage);

  @override
  Future<String> uploadImage({
    required String conversationId,
    required String senderId,
    required String filePath,
  }) async {
    final file = File(filePath);

    final extension = path.extension(filePath);

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}$extension';

    final ref = storage.ref().child(
      'chat_media/$conversationId/images/$fileName',
    );

    await ref.putFile(file);

    return await ref.getDownloadURL();
  }

 @override
Future<MediaUploadResult> uploadVideo({
  required String conversationId,
  required String senderId,
  required String filePath,
}) async {
  final file = File(filePath);

  final extension = path.extension(filePath);

  final fileName =
      '${DateTime.now().millisecondsSinceEpoch}$extension';

  // Native thumbnail generation
  String? thumbnailPath;

  try {
    thumbnailPath =
        await NativeThumbnailService.generateThumbnail(
      videoPath: filePath,
    );

    debugPrint(
      'Native Thumbnail Path: $thumbnailPath',
    );
  } catch (e) {
    debugPrint(
      'Thumbnail generation failed: $e',
    );
  }

  final ref = storage.ref().child(
    'chat_media/$conversationId/videos/$fileName',
  );

  await ref.putFile(file);

  final videoUrl = await ref.getDownloadURL();
  String? thumbnailUrl;

if (thumbnailPath != null) {
  final thumbFile = File(thumbnailPath);

  if (await thumbFile.exists()) {
    final thumbRef = storage.ref().child(
      'chat_media/$conversationId/video_thumbnails/${path.basenameWithoutExtension(fileName)}.jpg',
    );

    await thumbRef.putFile(thumbFile);

    thumbnailUrl = await thumbRef.getDownloadURL();
  }
}

  return MediaUploadResult(
  mediaUrl: videoUrl,
  thumbnailUrl: thumbnailUrl,
);
}
  @override
  Future<String> uploadFile({
    required String conversationId,
    required String senderId,
    required String filePath,
    required String fileName,
  }) async {
    final file = File(filePath);

    final ref = storage.ref().child(
      'chat_media/$conversationId/files/$fileName',
    );

    await ref.putFile(file);

    return await ref.getDownloadURL();
  }

  @override
  Future<void> deleteMedia(String downloadUrl) async {
    final ref = storage.refFromURL(downloadUrl);

    await ref.delete();
  }
}