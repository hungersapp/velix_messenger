import 'dart:io';

import 'package:image_picker/image_picker.dart';


class MediaPickerService {
  MediaPickerService._();

  static final ImagePicker _picker = ImagePicker();

  /// Pick Image from Gallery
  static Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) {
      return null;
    }

    return File(image.path);
  }

  /// Pick Video from Gallery
  static Future<File?> pickVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );

    if (video == null) {
      return null;
    }

    return File(video.path);
  }

  /// Capture Image using Camera
  static Future<File?> captureImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) {
      return null;
    }

    return File(image.path);
  }

  /// Record Video using Camera
  static Future<File?> recordVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 5),
    );

    if (video == null) {
      return null;
    }

    return File(video.path);
  }
}