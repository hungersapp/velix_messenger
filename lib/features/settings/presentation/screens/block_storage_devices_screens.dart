import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/entities/settings_models.dart';
import '../providers/settings_feature_providers.dart';

class BlockedUsersSettingsScreen extends ConsumerWidget {
  const BlockedUsersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(blockedUsersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: blockedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text(
                'No blocked users',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoUrl.trim().isNotEmpty
                      ? NetworkImage(user.photoUrl)
                      : null,
                  child: user.photoUrl.trim().isEmpty
                      ? Text(user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?')
                      : null,
                ),
                title: Text(user.displayName),
                subtitle: Text(user.velixId),
                trailing: TextButton(
                  onPressed: () async {
                    final me = ref.read(currentUserProvider).valueOrNull;
                    if (me == null) return;
                    await ref.read(settingsRepositoryProvider).unblockUser(
                          currentUserId: me.uid,
                          blockedUserId: user.uid,
                        );
                  },
                  child: const Text('Unblock'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class StorageUsageSettingsScreen extends ConsumerWidget {
  const StorageUsageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(storageUsageBytesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Usage'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(Icons.folder_outlined, color: colorScheme.primary),
            title: const Text('Media cache'),
            subtitle: Text(
              usageAsync.when(
                loading: () => 'Calculating…',
                error: (_, _) => 'Unavailable',
                data: _formatBytes,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              await ref.read(settingsRepositoryProvider).clearMediaCache();
              ref.invalidate(storageUsageBytesProvider);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class MediaAutoDownloadSettingsScreen extends ConsumerWidget {
  const MediaAutoDownloadSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(autoDownloadSettingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final settings = settingsAsync.valueOrNull ?? const AutoDownloadSettings();

    Future<void> update(AutoDownloadSettings next) async {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) return;
      await ref
          .read(settingsRepositoryProvider)
          .setAutoDownloadSettings(user.uid, next);
      ref.invalidate(autoDownloadSettingsProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Auto Download'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Material(
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.photo_outlined, color: colorScheme.primary),
                  title: const Text('Photos'),
                  value: settings.photos,
                  onChanged: (v) => update(settings.copyWith(photos: v)),
                ),
                SwitchListTile(
                  secondary: Icon(Icons.videocam_outlined, color: colorScheme.primary),
                  title: const Text('Videos'),
                  value: settings.videos,
                  onChanged: (v) => update(settings.copyWith(videos: v)),
                ),
                SwitchListTile(
                  secondary: Icon(Icons.insert_drive_file_outlined, color: colorScheme.primary),
                  title: const Text('Documents'),
                  value: settings.documents,
                  onChanged: (v) => update(settings.copyWith(documents: v)),
                ),
                SwitchListTile(
                  secondary: Icon(Icons.mic_none_rounded, color: colorScheme.primary),
                  title: const Text('Voice Messages'),
                  value: settings.voiceMessages,
                  onChanged: (v) => update(settings.copyWith(voiceMessages: v)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveDevicesSettingsScreen extends ConsumerWidget {
  const ActiveDevicesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(activeDevicesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Devices'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (devices) {
          if (devices.isEmpty) {
            return const Center(child: Text('No devices registered yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: devices.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                leading: Icon(
                  Icons.devices_outlined,
                  color: colorScheme.primary,
                ),
                title: Text(
                  device.isCurrent ? '${device.name} (This device)' : device.name,
                ),
                subtitle: Text(
                  'Last active · ${DateFormat.yMMMd().add_jm().format(device.lastActiveAt)}',
                ),
                trailing: device.isCurrent
                    ? null
                    : TextButton(
                        onPressed: () async {
                          final user =
                              ref.read(currentUserProvider).valueOrNull;
                          if (user == null) return;
                          await ref.read(settingsRepositoryProvider).revokeDevice(
                                userId: user.uid,
                                deviceId: device.id,
                              );
                          ref.invalidate(activeDevicesProvider);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Device signed out'),
                            ),
                          );
                        },
                        child: const Text('Sign out'),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
