import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class MediaPickerService {
  MediaPickerService._();

  static final ImagePicker _picker = ImagePicker();

  /// Pick Image from Gallery
  static Future<File?> pickImageFromGallery() async {
    return _pickImage(ImageSource.gallery);
  }

  /// Pick Video from Gallery
  static Future<File?> pickVideoFromGallery() async {
    return _pickVideo(ImageSource.gallery);
  }

  /// Capture Image using Camera
  static Future<File?> captureImage() async {
    return _pickImage(ImageSource.camera);
  }

  /// Record Video using Camera
  static Future<File?> recordVideo() async {
    return _pickVideo(ImageSource.camera);
  }

  static Future<File?> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null) return null;
      return File(image.path);
    } on PlatformException catch (e) {
      throw Exception(_mapPickerError(e, isCamera: source == ImageSource.camera));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to open the photo picker. Please try again.');
    }
  }

  static Future<File?> _pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
      if (video == null) return null;
      return File(video.path);
    } on PlatformException catch (e) {
      throw Exception(_mapPickerError(e, isCamera: source == ImageSource.camera));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to open the video picker. Please try again.');
    }
  }

  static String _mapPickerError(PlatformException e, {required bool isCamera}) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    if (code.contains('photo') ||
        code.contains('camera') ||
        code.contains('permission') ||
        message.contains('permission') ||
        message.contains('denied') ||
        message.contains('access')) {
      return isCamera
          ? 'Camera permission is required. Enable it in Settings.'
          : 'Photo library permission is required. Enable it in Settings.';
    }
    return isCamera
        ? 'Unable to use the camera. Please try again.'
        : 'Unable to open your photo library. Please try again.';
  }
}
