import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/security/secure_storage_service.dart';
import '../../domain/entities/settings_models.dart';

class SettingsLocalDatasource {
  SettingsLocalDatasource({
    this._prefs,
    SecureStorageService? secureStorage,
  }) : _secureStorage = secureStorage ?? SecureStorageService();

  SharedPreferences? _prefs;
  final SecureStorageService _secureStorage;

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  String _k(String userId, String key) => 'settings_${userId}_$key';

  Future<String?> getWallpaperPath(String userId) async {
    return (await _p).getString(_k(userId, 'wallpaper'));
  }

  Future<void> setWallpaperPath(String userId, String? path) async {
    final prefs = await _p;
    final key = _k(userId, 'wallpaper');
    if (path == null || path.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, path);
    }
  }

  Future<ChatFontSizeOption> getFontSize(String userId) async {
    return ChatFontSizeOption.fromStorage(
      (await _p).getString(_k(userId, 'font_size')),
    );
  }

  Future<void> setFontSize(String userId, ChatFontSizeOption size) async {
    await (await _p).setString(_k(userId, 'font_size'), size.name);
  }

  Future<AutoDownloadSettings> getAutoDownload(String userId) async {
    final prefs = await _p;
    return AutoDownloadSettings(
      photos: prefs.getBool(_k(userId, 'dl_photos')) ?? true,
      videos: prefs.getBool(_k(userId, 'dl_videos')) ?? false,
      documents: prefs.getBool(_k(userId, 'dl_docs')) ?? false,
      voiceMessages: prefs.getBool(_k(userId, 'dl_voice')) ?? true,
    );
  }

  Future<void> setAutoDownload(
    String userId,
    AutoDownloadSettings settings,
  ) async {
    final prefs = await _p;
    await prefs.setBool(_k(userId, 'dl_photos'), settings.photos);
    await prefs.setBool(_k(userId, 'dl_videos'), settings.videos);
    await prefs.setBool(_k(userId, 'dl_docs'), settings.documents);
    await prefs.setBool(_k(userId, 'dl_voice'), settings.voiceMessages);
  }

  Future<String> getOrCreateDeviceId() => _secureStorage.getOrCreateDeviceId();

  Future<String> persistWallpaperFile(String userId, File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final wallpapers = Directory(p.join(dir.path, 'wallpapers', userId));
    if (!await wallpapers.exists()) {
      await wallpapers.create(recursive: true);
    }
    final dest = File(
      p.join(
        wallpapers.path,
        'chat_wallpaper${p.extension(source.path).isEmpty ? '.jpg' : p.extension(source.path)}',
      ),
    );
    if (await dest.exists()) {
      await dest.delete();
    }
    await source.copy(dest.path);
    await setWallpaperPath(userId, dest.path);
    return dest.path;
  }

  Future<void> deleteWallpaperFile(String userId) async {
    final path = await getWallpaperPath(userId);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await setWallpaperPath(userId, null);
  }

  Future<int> estimateCacheBytes() async {
    var total = 0;
    try {
      final cacheDir = await getTemporaryDirectory();
      total += await _dirSize(cacheDir);
    } catch (_) {}
    try {
      final docs = await getApplicationDocumentsDirectory();
      final cache = Directory(p.join(docs.path, 'libCachedImageData'));
      if (await cache.exists()) {
        total += await _dirSize(cache);
      }
    } catch (_) {}
    return total;
  }

  Future<void> clearMediaCache() async {
    try {
      await DefaultCacheManager().emptyCache();
    } catch (_) {}
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<int> _dirSize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }
}
