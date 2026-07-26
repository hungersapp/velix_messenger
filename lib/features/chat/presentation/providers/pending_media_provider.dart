import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PendingMediaType { image, video, file, voice }

class PendingMedia {
  final String id;
  final String conversationId;
  final PendingMediaType mediaType;
  final String localPath;
  final String? localThumbnailPath;
  final String? fileName;
  final int? fileSize;
  final int? durationMs;
  final DateTime createdAt;

  const PendingMedia({
    required this.id,
    required this.conversationId,
    required this.mediaType,
    required this.localPath,
    this.localThumbnailPath,
    this.fileName,
    this.fileSize,
    this.durationMs,
    required this.createdAt,
  });
}

class PendingMediaNotifier extends StateNotifier<List<PendingMedia>> {
  PendingMediaNotifier() : super(const []);

  String add({
    required String conversationId,
    required PendingMediaType mediaType,
    required String localPath,
    String? localThumbnailPath,
    String? fileName,
    int? fileSize,
    int? durationMs,
  }) {
    final id = '${DateTime.now().microsecondsSinceEpoch}_$localPath';

    state = [
      ...state,
      PendingMedia(
        id: id,
        conversationId: conversationId,
        mediaType: mediaType,
        localPath: localPath,
        localThumbnailPath: localThumbnailPath,
        fileName: fileName,
        fileSize: fileSize,
        durationMs: durationMs,
        createdAt: DateTime.now(),
      ),
    ];

    return id;
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void removeByConversation(String conversationId) {
    state = state
        .where((item) => item.conversationId != conversationId)
        .toList();
  }
}

final pendingMediaProvider =
    StateNotifierProvider<PendingMediaNotifier, List<PendingMedia>>(
  (ref) => PendingMediaNotifier(),
);
