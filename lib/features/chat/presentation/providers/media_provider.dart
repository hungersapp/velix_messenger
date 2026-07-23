import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/media_remote_datasource.dart';
import '../../data/datasources/media_remote_datasource_impl.dart';
import '../../data/repositories/media_repository_impl.dart';
import '../../domain/repositories/media_repository.dart';
import '../../domain/usecases/upload_file_usecase.dart';
import '../../domain/usecases/upload_image_usecase.dart';
import '../../domain/usecases/upload_video_usecase.dart';
import '../../domain/entities/media_upload_result.dart';

/// Firebase Storage
final firebaseStorageProvider =
    Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

/// Remote DataSource
final mediaRemoteDataSourceProvider =
    Provider<MediaRemoteDataSource>(
  (ref) => MediaRemoteDataSourceImpl(
    ref.read(firebaseStorageProvider),
  ),
);

/// Repository
final mediaRepositoryProvider =
    Provider<MediaRepository>(
  (ref) => MediaRepositoryImpl(
    ref.read(mediaRemoteDataSourceProvider),
  ),
);

/// Upload Image
final uploadImageUseCaseProvider =
    Provider<UploadImageUseCase>(
  (ref) => UploadImageUseCase(
    ref.read(mediaRepositoryProvider),
  ),
);

/// Upload Video
final uploadVideoUseCaseProvider =
    Provider<UploadVideoUseCase>(
  (ref) => UploadVideoUseCase(
    ref.read(mediaRepositoryProvider),
  ),
);

/// Upload File
final uploadFileUseCaseProvider =
    Provider<UploadFileUseCase>(
  (ref) => UploadFileUseCase(
    ref.read(mediaRepositoryProvider),
  ),
);

class MediaController extends StateNotifier<bool> {
  MediaController(this.ref) : super(false);

  final Ref ref;

  Future<String> uploadImage({
    required String conversationId,
    required String senderId,
    required String filePath,
  }) async {
    state = true;

    try {
      return await ref
          .read(uploadImageUseCaseProvider)
          .call(
            conversationId: conversationId,
            senderId: senderId,
            filePath: filePath,
          );
    } finally {
      state = false;
    }
  }

  Future<MediaUploadResult> uploadVideo({
  required String conversationId,
  required String senderId,
  required String filePath,
}) async {
  state = true;

  try {
    return await ref
        .read(uploadVideoUseCaseProvider)
        .call(
          conversationId: conversationId,
          senderId: senderId,
          filePath: filePath,
        );
  } finally {
    state = false;
  }
}

  Future<String> uploadFile({
    required String conversationId,
    required String senderId,
    required String filePath,
    required String fileName,
  }) async {
    state = true;

    try {
      return await ref
          .read(uploadFileUseCaseProvider)
          .call(
            conversationId: conversationId,
            senderId: senderId,
            filePath: filePath,
            fileName: fileName,
          );
    } finally {
      state = false;
    }
  }
}

final mediaControllerProvider =
    StateNotifierProvider<MediaController, bool>(
  (ref) => MediaController(ref),
);