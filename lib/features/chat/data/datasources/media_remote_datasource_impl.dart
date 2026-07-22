import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

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
  Future<String> uploadVideo({
    required String conversationId,
    required String senderId,
    required String filePath,
  }) async {
    final file = File(filePath);

    final extension = path.extension(filePath);

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}$extension';

    final ref = storage.ref().child(
      'chat_media/$conversationId/videos/$fileName',
    );

    await ref.putFile(file);

    return await ref.getDownloadURL();
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