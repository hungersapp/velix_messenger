import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

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
  }) async {
    final ref = _storage.ref(path);

    final task = await ref.putData(
      bytes,
      metadata ??
          SettableMetadata(
            contentType: contentType,
          ),
    );

    return task.ref.getDownloadURL();
  }

  Future<String> uploadFile({
    required String path,
    required dynamic file,
    String? contentType,
    SettableMetadata? metadata,
  }) async {
    final ref = _storage.ref(path);

    final task = await ref.putFile(
      file,
      metadata ??
          SettableMetadata(
            contentType: contentType,
          ),
    );

    return task.ref.getDownloadURL();
  }

  Future<void> delete(String path) async {
    await _storage.ref(path).delete();
  }

  Future<String> getDownloadUrl(String path) async {
    return _storage.ref(path).getDownloadURL();
  }

  Future<FullMetadata> getMetadata(String path) async {
    return _storage.ref(path).getMetadata();
  }

  Future<void> updateMetadata({
    required String path,
    required SettableMetadata metadata,
  }) async {
    await _storage.ref(path).updateMetadata(metadata);
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

    return task.snapshotEvents;
  }
}
