import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/secure_storage_providers.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/datasources/settings_remote_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/settings_models.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsLocalDatasourceProvider =
    Provider<SettingsLocalDatasource>((ref) {
  return SettingsLocalDatasource(
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});

final settingsRemoteDatasourceProvider =
    Provider<SettingsRemoteDatasource>((ref) {
  return SettingsRemoteDatasource();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    local: ref.watch(settingsLocalDatasourceProvider),
    remote: ref.watch(settingsRemoteDatasourceProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});

final chatWallpaperPathProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return null;
  return ref.watch(settingsRepositoryProvider).getChatWallpaperPath(user.uid);
});

final chatFontSizeProvider = FutureProvider<ChatFontSizeOption>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return ChatFontSizeOption.medium;
  return ref.watch(settingsRepositoryProvider).getChatFontSize(user.uid);
});

final autoDownloadSettingsProvider =
    FutureProvider<AutoDownloadSettings>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const AutoDownloadSettings();
  return ref
      .watch(settingsRepositoryProvider)
      .getAutoDownloadSettings(user.uid);
});

final privacySettingsProvider = FutureProvider<PrivacySettings>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const PrivacySettings();
  return ref.watch(settingsRepositoryProvider).getPrivacySettings(user.uid);
});

final blockedUsersProvider = StreamProvider<List<BlockedUser>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) {
    return Stream<List<BlockedUser>>.value(const []);
  }
  return ref.watch(settingsRepositoryProvider).watchBlockedUsers(user.uid);
});

final twoFactorEnabledProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return false;
  return ref.watch(settingsRepositoryProvider).isTwoFactorEnabled(user.uid);
});

final storageUsageBytesProvider = FutureProvider<int>((ref) {
  return ref.watch(settingsRepositoryProvider).estimateCacheBytes();
});

final activeDevicesProvider = FutureProvider<List<ActiveDevice>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const [];
  final repo = ref.watch(settingsRepositoryProvider);
  final deviceId = await repo.getOrCreateDeviceId();
  return repo.getActiveDevices(
    userId: user.uid,
    currentDeviceId: deviceId,
  );
});

/// Registers this device session for Active Devices.
/// Signs out immediately if this device was revoked remotely.
/// Throttled so resume / rebuilds do not re-register every frame.
final deviceSessionBootstrapProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return;

  final now = DateTime.now();
  final last = _lastDeviceBootstrapAt;
  if (last != null && now.difference(last) < const Duration(seconds: 45)) {
    return;
  }
  _lastDeviceBootstrapAt = now;

  final repo = ref.watch(settingsRepositoryProvider);
  final deviceId = await repo.getOrCreateDeviceId();
  final revoked = await repo.isDeviceRevoked(
    userId: user.uid,
    deviceId: deviceId,
  );
  if (revoked) {
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(currentUserProvider);
    return;
  }
  await repo.registerCurrentDevice(
    userId: user.uid,
    device: ActiveDevice(
      id: deviceId,
      name: _deviceName(),
      platform: _platformName(),
      lastActiveAt: DateTime.now(),
      isCurrent: true,
    ),
  );
});

DateTime? _lastDeviceBootstrapAt;

String _platformName() {
  if (kIsWeb) return 'Web';
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isWindows) return 'Windows';
  if (Platform.isMacOS) return 'macOS';
  if (Platform.isLinux) return 'Linux';
  return 'Unknown';
}

String _deviceName() {
  final platform = _platformName();
  return 'Velix on $platform';
}
