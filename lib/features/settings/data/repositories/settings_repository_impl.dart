import 'dart:io';

import '../../../../core/security/secure_storage_service.dart';
import '../../domain/entities/settings_models.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../datasources/settings_remote_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required this._local,
    required this._remote,
    SecureStorageService? secureStorage,
  }) : _secureStorage = secureStorage ?? SecureStorageService();

  final SettingsLocalDatasource _local;
  final SettingsRemoteDatasource _remote;
  final SecureStorageService _secureStorage;

  @override
  Future<String?> getChatWallpaperPath(String userId) =>
      _local.getWallpaperPath(userId);

  @override
  Future<void> setChatWallpaperPath(String userId, String? localPath) =>
      _local.setWallpaperPath(userId, localPath);

  @override
  Future<String> saveWallpaperFromFile(String userId, File file) =>
      _local.persistWallpaperFile(userId, file);

  @override
  Future<void> removeWallpaper(String userId) =>
      _local.deleteWallpaperFile(userId);

  @override
  Future<ChatFontSizeOption> getChatFontSize(String userId) =>
      _local.getFontSize(userId);

  @override
  Future<void> setChatFontSize(String userId, ChatFontSizeOption size) =>
      _local.setFontSize(userId, size);

  @override
  Future<AutoDownloadSettings> getAutoDownloadSettings(String userId) =>
      _local.getAutoDownload(userId);

  @override
  Future<void> setAutoDownloadSettings(
    String userId,
    AutoDownloadSettings settings,
  ) =>
      _local.setAutoDownload(userId, settings);

  @override
  Future<PrivacySettings> getPrivacySettings(String userId) =>
      _remote.getPrivacySettings(userId);

  @override
  Future<void> updatePrivacySettings(
    String userId,
    PrivacySettings settings,
  ) =>
      _remote.updatePrivacySettings(userId, settings);

  @override
  Stream<List<BlockedUser>> watchBlockedUsers(String userId) =>
      _remote.watchBlockedUsers(userId);

  @override
  Future<void> blockUser({
    required String currentUserId,
    required BlockedUser user,
  }) =>
      _remote.blockUser(currentUserId: currentUserId, user: user);

  @override
  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) =>
      _remote.unblockUser(
        currentUserId: currentUserId,
        blockedUserId: blockedUserId,
      );

  @override
  Future<bool> isBlockedEitherWay({
    required String userA,
    required String userB,
  }) =>
      _remote.isBlockedEitherWay(userA: userA, userB: userB);

  @override
  Future<List<ActiveDevice>> getActiveDevices({
    required String userId,
    required String currentDeviceId,
  }) =>
      _remote.getActiveDevices(
        userId: userId,
        currentDeviceId: currentDeviceId,
      );

  @override
  Future<void> registerCurrentDevice({
    required String userId,
    required ActiveDevice device,
  }) =>
      _remote.registerCurrentDevice(userId: userId, device: device);

  @override
  Future<void> revokeDevice({
    required String userId,
    required String deviceId,
  }) =>
      _remote.revokeDevice(userId: userId, deviceId: deviceId);

  @override
  Future<String> getOrCreateDeviceId() => _local.getOrCreateDeviceId();

  @override
  Future<bool> isDeviceRevoked({
    required String userId,
    required String deviceId,
  }) =>
      _remote.isDeviceRevoked(userId: userId, deviceId: deviceId);

  @override
  Future<bool> isTwoFactorEnabled(String userId) =>
      _remote.isTwoFactorEnabled(userId);

  @override
  Future<String> beginTwoFactorEnrollment(String userId) =>
      _remote.generateTwoFactorSecret();

  @override
  Future<void> confirmTwoFactor({
    required String userId,
    required String secret,
    required String otp,
  }) async {
    await _remote.confirmTwoFactor(userId: userId, secret: secret, otp: otp);
    await _secureStorage.setTotpEnabled(true);
  }

  @override
  Future<void> disableTwoFactor({
    required String userId,
    required String otp,
  }) async {
    await _remote.disableTwoFactor(userId: userId, otp: otp);
    await _secureStorage.setTotpEnabled(false);
  }

  @override
  Future<bool> verifyLoginTotp(String otp) =>
      _remote.verifyCurrentUserTotp(otp);

  @override
  Future<void> submitSupportRequest({
    required String userId,
    required String type,
    required String message,
  }) =>
      _remote.submitSupportRequest(
        userId: userId,
        type: type,
        message: message,
      );

  @override
  Future<int> estimateCacheBytes() => _local.estimateCacheBytes();

  @override
  Future<void> clearMediaCache() => _local.clearMediaCache();
}
