import 'dart:io';

import '../entities/settings_models.dart';

abstract class SettingsRepository {
  Future<String?> getChatWallpaperPath(String userId);

  Future<void> setChatWallpaperPath(String userId, String? localPath);

  Future<String> saveWallpaperFromFile(String userId, File file);

  Future<void> removeWallpaper(String userId);

  Future<ChatFontSizeOption> getChatFontSize(String userId);

  Future<void> setChatFontSize(String userId, ChatFontSizeOption size);

  Future<AutoDownloadSettings> getAutoDownloadSettings(String userId);

  Future<void> setAutoDownloadSettings(
    String userId,
    AutoDownloadSettings settings,
  );

  Future<PrivacySettings> getPrivacySettings(String userId);

  Future<void> updatePrivacySettings(String userId, PrivacySettings settings);

  Stream<List<BlockedUser>> watchBlockedUsers(String userId);

  Future<void> blockUser({
    required String currentUserId,
    required BlockedUser user,
  });

  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  });

  Future<bool> isBlockedEitherWay({
    required String userA,
    required String userB,
  });

  Future<List<ActiveDevice>> getActiveDevices({
    required String userId,
    required String currentDeviceId,
  });

  Future<void> registerCurrentDevice({
    required String userId,
    required ActiveDevice device,
  });

  Future<void> revokeDevice({
    required String userId,
    required String deviceId,
  });

  Future<String> getOrCreateDeviceId();

  Future<bool> isDeviceRevoked({
    required String userId,
    required String deviceId,
  });

  Future<bool> isTwoFactorEnabled(String userId);

  Future<String> beginTwoFactorEnrollment(String userId);

  Future<void> confirmTwoFactor({
    required String userId,
    required String secret,
    required String otp,
  });

  Future<void> disableTwoFactor({
    required String userId,
    required String otp,
  });

  Future<bool> verifyLoginTotp(String otp);

  Future<void> submitSupportRequest({
    required String userId,
    required String type,
    required String message,
  });

  Future<int> estimateCacheBytes();

  Future<void> clearMediaCache();
}
