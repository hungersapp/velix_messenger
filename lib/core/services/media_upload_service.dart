import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class MediaUploadService {
  MediaUploadService._();

  static final FirebaseStorage _storage =
      FirebaseStorage.instance;

  /// Upload Image
  static Future<String> uploadImage({
    required File file,
    required String conversationId,
  }) async {
    return _uploadFile(
      file: file,
      folder: 'images',
      conversationId: conversationId,
    );
  }

  /// Upload Video
  static Future<String> uploadVideo({
    required File file,
    required String conversationId,
  }) async {
    return _uploadFile(
      file: file,
      folder: 'videos',
      conversationId: conversationId,
    );
  }

  /// Common Upload Method
  static Future<String> _uploadFile({
    required File file,
    required String folder,
    required String conversationId,
  }) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';

    final reference = _storage.ref().child(
          'chat_media/$conversationId/$folder/$fileName',
        );

    final uploadTask = reference.putFile(file);

    await uploadTask;

    return reference.getDownloadURL();
  }
}