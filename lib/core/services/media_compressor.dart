import 'dart:io';

/// Enterprise media compressor abstraction.
///
/// This version is dependency-free. Plug in packages such as
/// flutter_image_compress or video_compress inside the TODO sections.
class MediaCompressor {
  const MediaCompressor();

  static const int defaultImageQuality = 80;
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;

  Future<File> compressImage(
    File file, {
    int quality = defaultImageQuality,
    int maxWidth = maxImageWidth,
    int maxHeight = maxImageHeight,
  }) async {
    // TODO:
    // Integrate flutter_image_compress here.
    // Validate dimensions.
    // Strip unnecessary EXIF if required.
    return file;
  }

  Future<File> compressVideo(
    File file,
  ) async {
    // TODO:
    // Integrate video_compress here.
    return file;
  }

  Future<File?> generateVideoThumbnail(
    File videoFile,
  ) async {
    // TODO:
    // Integrate video_thumbnail package.
    return null;
  }

  Future<int> fileSize(File file) async {
    return await file.length();
  }

  Future<bool> exceedsLimit(
    File file, {
    required int maxBytes,
  }) async {
    return (await file.length()) > maxBytes;
  }

  Future<void> deleteTemporaryFile(
    File? file,
  ) async {
    if (file == null) return;

    if (await file.exists()) {
      await file.delete();
    }
  }
}
