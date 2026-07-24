import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';

import '../../../../core/services/native_thumbnail_service.dart';

class TimeCapsuleMediaException implements Exception {
  TimeCapsuleMediaException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TimeCapsulePickedMedia {
  const TimeCapsulePickedMedia({
    required this.file,
    required this.mediaType,
    required this.durationMs,
    this.thumbnailPath,
  });

  final File file;
  final String mediaType;
  final int durationMs;
  final String? thumbnailPath;
}

/// Time Capsule–specific picker. Does not modify Chat media APIs.
class TimeCapsuleMediaService {
  TimeCapsuleMediaService({
    ImagePicker? picker,
  }) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const Duration maxVideoDuration = Duration(seconds: 30);
  static const int defaultImageDurationMs = 5000;

  Future<TimeCapsulePickedMedia?> pickImage({
    required ImageSource source,
  }) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 100,
    );
    if (picked == null) return null;

    final compressed = await _compressImage(File(picked.path));
    return TimeCapsulePickedMedia(
      file: compressed,
      mediaType: 'image',
      durationMs: defaultImageDurationMs,
    );
  }

  Future<TimeCapsulePickedMedia?> pickVideo({
    required ImageSource source,
  }) async {
    final XFile? picked = await _picker.pickVideo(
      source: source,
      maxDuration: maxVideoDuration,
    );
    if (picked == null) return null;

    final file = File(picked.path);
    final durationMs = await _videoDurationMs(file);

    if (durationMs > maxVideoDuration.inMilliseconds) {
      throw TimeCapsuleMediaException(
        'Video must be 30 seconds or less.',
      );
    }

    String? thumbnailPath;
    try {
      thumbnailPath = await NativeThumbnailService.generateThumbnail(
        videoPath: file.path,
      );
    } catch (_) {
      thumbnailPath = null;
    }

    return TimeCapsulePickedMedia(
      file: file,
      mediaType: 'video',
      durationMs: durationMs <= 0 ? defaultImageDurationMs : durationMs,
      thumbnailPath: thumbnailPath,
    );
  }

  Future<File> _compressImage(File imageFile) async {
    final targetPath = path.join(
      imageFile.parent.path,
      '${path.basenameWithoutExtension(imageFile.path)}_tc.jpg',
    );

    final XFile? compressed =
        await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: 80,
      minWidth: 1280,
      minHeight: 1280,
    );

    if (compressed == null) {
      return imageFile;
    }

    return File(compressed.path);
  }

  Future<int> _videoDurationMs(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return controller.value.duration.inMilliseconds;
    } finally {
      await controller.dispose();
    }
  }
}
