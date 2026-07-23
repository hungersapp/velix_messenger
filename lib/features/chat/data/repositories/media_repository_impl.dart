import '../../domain/repositories/media_repository.dart';
import '../datasources/media_remote_datasource.dart';
import '../../domain/entities/media_upload_result.dart';

class MediaRepositoryImpl implements MediaRepository {
  final MediaRemoteDataSource remoteDataSource;

  MediaRepositoryImpl(this.remoteDataSource);

  @override
  Future<String> uploadImage({
    required String conversationId,
    required String senderId,
    required String filePath,
  }) {
    return remoteDataSource.uploadImage(
      conversationId: conversationId,
      senderId: senderId,
      filePath: filePath,
    );
  }

  @override
Future<MediaUploadResult> uploadVideo({
  required String conversationId,
  required String senderId,
  required String filePath,
}) {
  return remoteDataSource.uploadVideo(
    conversationId: conversationId,
    senderId: senderId,
    filePath: filePath,
  );
}

  @override
  Future<String> uploadFile({
    required String conversationId,
    required String senderId,
    required String filePath,
    required String fileName,
  }) {
    return remoteDataSource.uploadFile(
      conversationId: conversationId,
      senderId: senderId,
      filePath: filePath,
      fileName: fileName,
    );
  }
}