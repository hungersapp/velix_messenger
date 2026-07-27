import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import '../../../../core/firebase/firebase_error_guard.dart';
import '../../../../core/services/native_thumbnail_service.dart';
import '../../domain/entities/media_upload_result.dart';

import 'media_remote_datasource.dart';

class MediaRemoteDataSourceImpl implements MediaRemoteDataSource {
  final FirebaseStorage storage;

  MediaRemoteDataSourceImpl(this.storage);

  SettableMetadata _metadata({
    required String senderId,
    required String filePath,
    required String fileName,
    String? fallbackContentType,
  }) {
    // Prefer explicit fallbacks for known chat media so rules' contentType
    // checks never see application/octet-stream for image/audio/video/pdf.
    final contentType = fallbackContentType ??
        lookupMimeType(filePath) ??
        lookupMimeType(fileName) ??
        'application/octet-stream';

    if (senderId.isEmpty) {
      throw Exception('Upload failed: missing authenticated sender id.');
    }

    return SettableMetadata(
      contentType: contentType,
      customMetadata: <String, String>{
        'uploaderId': senderId,
      },
    );
  }

  void _assertUploadArgs({
    required String conversationId,
    required String senderId,
    required String filePath,
  }) {
    if (conversationId.isEmpty) {
      throw Exception('Upload failed: missing conversation id.');
    }
    if (senderId.isEmpty) {
      throw Exception('Upload failed: missing authenticated sender id.');
    }
    if (filePath.isEmpty) {
      throw Exception('Upload failed: missing local file path.');
    }
  }

  String _requireDownloadUrl(String url, String storagePath) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw Exception(
        'Upload finished but download URL was empty for path=$storagePath',
      );
    }
    return trimmed;
  }

  @override
  Future<String> uploadImage({
    required String conversationId,
    required String senderId,
    required String filePath,
  }) {
    return guardFirebase(() async {
      _assertUploadArgs(
        conversationId: conversationId,
        senderId: senderId,
        filePath: filePath,
      );
      final file = File(filePath);

      final extension = path.extension(filePath);

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}$extension';

      final storagePath = 'chat_media/$conversationId/images/$fileName';
      final metadata = _metadata(
        senderId: senderId,
        filePath: filePath,
        fileName: fileName,
        fallbackContentType: 'image/jpeg',
      );

      debugPrint(
        '[MediaUpload] image start conversationId=$conversationId '
        'senderId=$senderId path=$storagePath '
        'contentType=${metadata.contentType} uploaderId=${metadata.customMetadata?['uploaderId']}',
      );

      final ref = storage.ref().child(storagePath);

      try {
        await ref.putFile(file, metadata);
        final url = _requireDownloadUrl(await ref.getDownloadURL(), storagePath);
        debugPrint('[MediaUpload] image success url=$url');
        return url;
      } catch (e, st) {
        debugPrint('[MediaUpload] image failed path=$storagePath error=$e\n$st');
        rethrow;
      }
    }, context: 'MediaUpload.image');
  }

  @override
  Future<MediaUploadResult> uploadVideo({
    required String conversationId,
    required String senderId,
    required String filePath,
  }) {
    return guardFirebase(() async {
      _assertUploadArgs(
        conversationId: conversationId,
        senderId: senderId,
        filePath: filePath,
      );
      final file = File(filePath);

      final extension = path.extension(filePath);

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}$extension';

      // Native thumbnail generation
      String? thumbnailPath;

      try {
        thumbnailPath = await NativeThumbnailService.generateThumbnail(
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

      final storagePath = 'chat_media/$conversationId/videos/$fileName';
      final metadata = _metadata(
        senderId: senderId,
        filePath: filePath,
        fileName: fileName,
        fallbackContentType: 'video/mp4',
      );

      debugPrint(
        '[MediaUpload] video start conversationId=$conversationId '
        'senderId=$senderId path=$storagePath '
        'contentType=${metadata.contentType} uploaderId=${metadata.customMetadata?['uploaderId']}',
      );

      final ref = storage.ref().child(storagePath);

      try {
        await ref.putFile(file, metadata);
        final videoUrl =
            _requireDownloadUrl(await ref.getDownloadURL(), storagePath);
        debugPrint('[MediaUpload] video success url=$videoUrl');

        String? thumbnailUrl;

        if (thumbnailPath != null) {
          final thumbFile = File(thumbnailPath);

          if (await thumbFile.exists()) {
            final thumbName =
                '${path.basenameWithoutExtension(fileName)}.jpg';
            final thumbPath =
                'chat_media/$conversationId/video_thumbnails/$thumbName';
            final thumbRef = storage.ref().child(thumbPath);

            try {
              await thumbRef.putFile(
                thumbFile,
                _metadata(
                  senderId: senderId,
                  filePath: thumbnailPath,
                  fileName: thumbName,
                  fallbackContentType: 'image/jpeg',
                ),
              );

              thumbnailUrl = _requireDownloadUrl(
                await thumbRef.getDownloadURL(),
                thumbPath,
              );
              debugPrint('[MediaUpload] video thumb success url=$thumbnailUrl');
            } catch (e, st) {
              debugPrint(
                '[MediaUpload] video thumb failed path=$thumbPath error=$e\n$st',
              );
              rethrow;
            }
          }
        }

        return MediaUploadResult(
          mediaUrl: videoUrl,
          thumbnailUrl: thumbnailUrl,
        );
      } catch (e, st) {
        debugPrint('[MediaUpload] video failed path=$storagePath error=$e\n$st');
        rethrow;
      }
    }, context: 'MediaUpload.video');
  }

  @override
  Future<String> uploadFile({
    required String conversationId,
    required String senderId,
    required String filePath,
    required String fileName,
  }) {
    return guardFirebase(() async {
      _assertUploadArgs(
        conversationId: conversationId,
        senderId: senderId,
        filePath: filePath,
      );
      final file = File(filePath);

      final storagePath = 'chat_media/$conversationId/files/$fileName';

      final lower = fileName.toLowerCase();
      final fallback = lower.endsWith('.m4a') ||
              lower.endsWith('.aac') ||
              lower.endsWith('.mp4')
          ? 'audio/mp4'
          : lower.endsWith('.mp3')
              ? 'audio/mpeg'
              : lower.endsWith('.pdf')
                  ? 'application/pdf'
                  : lower.endsWith('.txt')
                      ? 'text/plain'
                      : lower.endsWith('.doc')
                          ? 'application/msword'
                          : lower.endsWith('.docx')
                              ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                              : lower.endsWith('.xls')
                                  ? 'application/vnd.ms-excel'
                                  : lower.endsWith('.xlsx')
                                      ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                                      : lower.endsWith('.ppt')
                                          ? 'application/vnd.ms-powerpoint'
                                          : lower.endsWith('.pptx')
                                              ? 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
                                              : lower.endsWith('.zip')
                                                  ? 'application/zip'
                                                  : null;

      final metadata = _metadata(
        senderId: senderId,
        filePath: filePath,
        fileName: fileName,
        fallbackContentType: fallback,
      );

      debugPrint(
        '[MediaUpload] file start conversationId=$conversationId '
        'senderId=$senderId path=$storagePath '
        'contentType=${metadata.contentType} uploaderId=${metadata.customMetadata?['uploaderId']}',
      );

      final ref = storage.ref().child(storagePath);

      try {
        await ref.putFile(file, metadata);
        final url = _requireDownloadUrl(await ref.getDownloadURL(), storagePath);
        debugPrint('[MediaUpload] file success url=$url');
        return url;
      } catch (e, st) {
        debugPrint('[MediaUpload] file failed path=$storagePath error=$e\n$st');
        rethrow;
      }
    }, context: 'MediaUpload.file');
  }

  @override
  Future<void> deleteMedia(String downloadUrl) {
    return guardFirebase(() async {
      final ref = storage.refFromURL(downloadUrl);
      await ref.delete();
    }, context: 'MediaUpload.delete');
  }
}
