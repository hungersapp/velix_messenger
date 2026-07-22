import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class MediaPickerService {
  MediaPickerService({
    ImagePicker? picker,
  }) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Pick Image from Gallery
  Future<File?> pickImageFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (file == null) return null;

    return File(file.path);
  }

  /// Pick Image from Camera
  Future<File?> pickImageFromCamera() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );

    if (file == null) return null;

    return File(file.path);
  }

  /// Pick Video
  Future<File?> pickVideo() async {
    final XFile? file = await _picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (file == null) return null;

    return File(file.path);
  }

  /// Compress Image
  Future<File?> compressImage(File imageFile) async {
    final targetPath = path.join(
      imageFile.parent.path,
      '${path.basenameWithoutExtension(imageFile.path)}_compressed.jpg',
    );

    final XFile? compressed =
        await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: 80,
      minWidth: 1280,
      minHeight: 1280,
    );

    if (compressed == null) return null;

    return File(compressed.path);
  }

  /// MIME Type
  String getMimeType(File file) {
    return lookupMimeType(file.path) ??
        'application/octet-stream';
  }

  /// Extension
  String getExtension(File file) {
    return path.extension(file.path);
  }

  /// File Name
  String getFileName(File file) {
    return path.basename(file.path);
  }

  /// File Size
  int getFileSize(File file) {
    return file.lengthSync();
  }
}