import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class PickedDocument {
  const PickedDocument({
    required this.file,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
  });

  final File file;
  final String fileName;
  final int fileSize;
  final String mimeType;
}

class MediaPickerService {
  MediaPickerService({
    ImagePicker? picker,
  }) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const int maxDocumentBytes = 25 * 1024 * 1024;

  static const List<String> documentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'zip',
  ];

  /// Pick Image from Gallery
  Future<File?> pickImageFromGallery() async {
    return _pickImage(ImageSource.gallery);
  }

  /// Pick Image from Camera
  Future<File?> pickImageFromCamera() async {
    return _pickImage(ImageSource.camera);
  }

  /// Pick Video
  Future<File?> pickVideo() async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (file == null) return null;
      return File(file.path);
    } on PlatformException catch (e) {
      throw Exception(_mapPickerError(e, isCamera: false, isVideo: true));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to open the video picker. Please try again.');
    }
  }

  /// Pick a supported document (PDF, Office, TXT, ZIP).
  Future<PickedDocument?> pickDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: documentExtensions,
        withData: false,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final platformFile = result.files.single;
      final filePath = platformFile.path;
      if (filePath == null || filePath.isEmpty) return null;

      final file = File(filePath);
      if (!file.existsSync()) return null;

      final fileSize = platformFile.size > 0
          ? platformFile.size
          : file.lengthSync();
      final fileName = platformFile.name.isNotEmpty
          ? platformFile.name
          : path.basename(filePath);
      final mimeType = lookupMimeType(filePath, headerBytes: null) ??
          lookupMimeType(fileName) ??
          'application/octet-stream';

      return PickedDocument(
        file: file,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
      );
    } on PlatformException catch (e) {
      throw Exception(_mapDocumentError(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to open the document picker. Please try again.');
    }
  }

  Future<File?> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );
      if (file == null) return null;
      return File(file.path);
    } on PlatformException catch (e) {
      throw Exception(
        _mapPickerError(e, isCamera: source == ImageSource.camera),
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to open the photo picker. Please try again.');
    }
  }

  /// Compress Image
  Future<File?> compressImage(File imageFile) async {
    try {
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
    } on PlatformException catch (e) {
      throw Exception(
        e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Unable to compress this image. Please try again.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to compress this image. Please try again.');
    }
  }

  /// MIME Type
  String getMimeType(File file) {
    return lookupMimeType(file.path) ?? 'application/octet-stream';
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

  static String _mapPickerError(
    PlatformException e, {
    required bool isCamera,
    bool isVideo = false,
  }) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    if (code.contains('photo') ||
        code.contains('camera') ||
        code.contains('permission') ||
        message.contains('permission') ||
        message.contains('denied') ||
        message.contains('access')) {
      if (isCamera) {
        return 'Camera permission is required. Enable it in Settings.';
      }
      return isVideo
          ? 'Photo library permission is required to pick a video. Enable it in Settings.'
          : 'Photo library permission is required. Enable it in Settings.';
    }
    if (isCamera) {
      return 'Unable to use the camera. Please try again.';
    }
    return isVideo
        ? 'Unable to open the video picker. Please try again.'
        : 'Unable to open your photo library. Please try again.';
  }

  static String _mapDocumentError(PlatformException e) {
    final message = (e.message ?? '').toLowerCase();
    if (message.contains('permission') || message.contains('denied')) {
      return 'Storage permission is required to pick a document. Enable it in Settings.';
    }
    return 'Unable to open the document picker. Please try again.';
  }
}
