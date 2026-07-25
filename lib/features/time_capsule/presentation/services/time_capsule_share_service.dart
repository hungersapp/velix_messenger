import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/story_entity.dart';

class TimeCapsuleShareException implements Exception {
  TimeCapsuleShareException([this.message = 'Unable to share this Time Capsule.']);

  final String message;

  @override
  String toString() => message;
}

/// Shares story media through the native share sheet.
class TimeCapsuleShareService {
  TimeCapsuleShareService({
    BaseCacheManager? cacheManager,
  }) : _cacheManager = cacheManager ?? DefaultCacheManager();

  final BaseCacheManager _cacheManager;

  static const String shareMessage = 'Shared from Velix Messenger';

  Future<void> shareStory(StoryEntity story) async {
    final mediaUrl = story.mediaUrl.trim();
    if (mediaUrl.isEmpty) {
      throw TimeCapsuleShareException();
    }

    try {
      final file = await _cacheManager.getSingleFile(mediaUrl);
      final isVideo = story.isVideo;
      final xFile = XFile(
        file.path,
        mimeType: isVideo ? 'video/mp4' : 'image/jpeg',
        name: isVideo ? 'velix_time_capsule.mp4' : 'velix_time_capsule.jpg',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: shareMessage,
        ),
      );
    } on TimeCapsuleShareException {
      rethrow;
    } catch (_) {
      throw TimeCapsuleShareException();
    }
  }
}
