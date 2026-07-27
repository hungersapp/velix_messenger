import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_error_guard.dart';

class FirebaseStorageService {
  FirebaseStorageService({
    FirebaseStorage? storage,
  }) : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
    SettableMetadata? metadata,
  }) {
    return guardFirebase(() async {
      final ref = _storage.ref(path);

      final task = await ref.putData(
        bytes,
        metadata ??
            SettableMetadata(
              contentType: contentType,
            ),
      );

      return task.ref.getDownloadURL();
    });
  }

  Future<String> uploadFile({
    required String path,
    required dynamic file,
    String? contentType,
    SettableMetadata? metadata,
  }) {
    return guardFirebase(() async {
      debugPrint(
        '[FirebaseStorageService] uploadFile path=$path '
        'contentType=${metadata?.contentType ?? contentType} '
        'uploaderId=${metadata?.customMetadata?['uploaderId']}',
      );
      final ref = _storage.ref(path);

      try {
        final task = await ref.putFile(
          file,
          metadata ??
              SettableMetadata(
                contentType: contentType,
              ),
        );

        final url = (await task.ref.getDownloadURL()).trim();
        if (url.isEmpty) {
          throw Exception(
            'Upload finished but download URL was empty for path=$path',
          );
        }
        debugPrint('[FirebaseStorageService] uploadFile success url=$url');
        return url;
      } catch (e, st) {
        debugPrint('[FirebaseStorageService] uploadFile failed path=$path error=$e\n$st');
        rethrow;
      }
    }, context: 'FirebaseStorageService.uploadFile');
  }

  Future<void> delete(String path) {
    return guardFirebase(() => _storage.ref(path).delete());
  }

  Future<String> getDownloadUrl(String path) {
    return guardFirebase(() => _storage.ref(path).getDownloadURL());
  }

  Future<FullMetadata> getMetadata(String path) {
    return guardFirebase(() => _storage.ref(path).getMetadata());
  }

  Future<void> updateMetadata({
    required String path,
    required SettableMetadata metadata,
  }) {
    return guardFirebase(
      () => _storage.ref(path).updateMetadata(metadata),
    );
  }

  Stream<TaskSnapshot> uploadFileWithProgress({
    required String path,
    required dynamic file,
    String? contentType,
    SettableMetadata? metadata,
  }) {
    final task = _storage.ref(path).putFile(
          file,
          metadata ??
              SettableMetadata(
                contentType: contentType,
              ),
        );

    return guardFirebaseStream(task.snapshotEvents);
  }
}
