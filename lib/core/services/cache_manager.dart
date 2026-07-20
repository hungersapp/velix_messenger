import 'dart:io';

class CacheManager {
  final Directory _cacheDirectory;

  CacheManager(this._cacheDirectory);

  Future<void> clearCache() async {
    if (await _cacheDirectory.exists()) {
      await _cacheDirectory.delete(recursive: true);
      await _cacheDirectory.create(recursive: true);
    }
  }

  Future<int> getCacheSize() async {
    if (!await _cacheDirectory.exists()) {
      return 0;
    }

    int size = 0;

    await for (final entity
        in _cacheDirectory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        size += await entity.length();
      }
    }

    return size;
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }
}