import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import '../firebase/firebase_error_guard.dart';

/// Legacy helper kept aligned with [MediaRemoteDataSourceImpl] Storage rules:
/// path `chat_media/{conversationId}/...` + `uploaderId` custom metadata.
class MediaUploadService {
  MediaUploadService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload Image
  static Future<String> uploadImage({
    required File file,
    required String conversationId,
    required String senderId,
  }) async {
    return _uploadFile(
      file: file,
      folder: 'images',
      conversationId: conversationId,
      senderId: senderId,
      fallbackContentType: 'image/jpeg',
    );
  }

  /// Upload Video
  static Future<String> uploadVideo({
    required File file,
    required String conversationId,
    required String senderId,
  }) async {
    return _uploadFile(
      file: file,
      folder: 'videos',
      conversationId: conversationId,
      senderId: senderId,
      fallbackContentType: 'video/mp4',
    );
  }

  /// Common Upload Method
  static Future<String> _uploadFile({
    required File file,
    required String folder,
    required String conversationId,
    required String senderId,
    String? fallbackContentType,
  }) {
    return guardFirebase(() async {
      if (conversationId.isEmpty) {
        throw Exception('Upload failed: missing conversation id.');
      }
      if (senderId.isEmpty) {
        throw Exception('Upload failed: missing authenticated sender id.');
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final storagePath = 'chat_media/$conversationId/$folder/$fileName';
      final contentType = fallbackContentType ??
          lookupMimeType(file.path) ??
          lookupMimeType(fileName) ??
          'application/octet-stream';

      debugPrint(
        '[MediaUploadService] start path=$storagePath '
        'senderId=$senderId contentType=$contentType',
      );

      final reference = _storage.ref().child(storagePath);

      try {
        await reference.putFile(
          file,
          SettableMetadata(
            contentType: contentType,
            customMetadata: <String, String>{'uploaderId': senderId},
          ),
        );

        final url = (await reference.getDownloadURL()).trim();
        if (url.isEmpty) {
          throw Exception(
            'Upload finished but download URL was empty for path=$storagePath',
          );
        }
        debugPrint('[MediaUploadService] success url=$url');
        return url;
      } catch (e, st) {
        debugPrint(
          '[MediaUploadService] failed path=$storagePath error=$e\n$st',
        );
        rethrow;
      }
    }, context: 'MediaUploadService');
  }
}
