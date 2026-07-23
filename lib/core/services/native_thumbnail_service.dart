import 'package:flutter/services.dart';

class NativeThumbnailService {
  NativeThumbnailService._();

  static const MethodChannel _channel =
      MethodChannel('velix/native_thumbnail');

  static Future<String?> generateThumbnail({
    required String videoPath,
  }) async {
    try {
      final String? thumbnailPath =
          await _channel.invokeMethod<String>(
        'generateThumbnail',
        {
          'videoPath': videoPath,
        },
      );

      return thumbnailPath;
    } on PlatformException catch (e) {
      throw Exception(
        'Thumbnail generation failed: ${e.message}',
      );
    }
  }
}