import 'dart:io';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_storage_service.dart';

enum UploadType {
  image,
  video,
  audio,
  document,
  profile,
}

class UploadResult {
  const UploadResult({
    required this.downloadUrl,
    required this.storagePath,
  });

  final String downloadUrl;
  final String storagePath;
}

class UploadManager {
  UploadManager(this._storageService);

  final FirebaseStorageService _storageService;

  Future<UploadResult> uploadFile({
    required File file,
    required String userId,
    required UploadType type,
    String? fileName,
    String? contentType,
  }) async {
    final storagePath = _buildPath(
      userId: userId,
      type: type,
      originalName: fileName ?? file.path.split('/').last,
    );

    final url = await _storageService.uploadFile(
      path: storagePath,
      file: file,
      contentType: contentType,
    );

    return UploadResult(
      downloadUrl: url,
      storagePath: storagePath,
    );
  }

  Stream<TaskSnapshot> uploadWithProgress({
    required File file,
    required String userId,
    required UploadType type,
    String? fileName,
    String? contentType,
  }) {
    final storagePath = _buildPath(
      userId: userId,
      type: type,
      originalName: fileName ?? file.path.split('/').last,
    );

    return _storageService.uploadFileWithProgress(
      path: storagePath,
      file: file,
      contentType: contentType,
    );
  }

  String _buildPath({
    required String userId,
    required UploadType type,
    required String originalName,
  }) {
    final String folder;

    switch (type) {
      case UploadType.image:
        folder = 'images';
        break;
      case UploadType.video:
        folder = 'videos';
        break;
      case UploadType.audio:
        folder = 'voice';
        break;
      case UploadType.document:
        folder = 'documents';
        break;
      case UploadType.profile:
        folder = 'profile';
        break;
    }

    final ext = originalName.contains('.')
        ? originalName.substring(originalName.lastIndexOf('.'))
        : '';

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);

    return 'users/$userId/$folder/${timestamp}_$random$ext';
  }
}