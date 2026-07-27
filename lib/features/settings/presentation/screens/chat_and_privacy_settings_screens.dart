import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/media_picker_service.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/entities/settings_models.dart';
import '../providers/settings_feature_providers.dart';

class ChatWallpaperSettingsScreen extends ConsumerWidget {
  const ChatWallpaperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpaperAsync = ref.watch(chatWallpaperPathProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Wallpaper'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: wallpaperAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(child: Text('Default wallpaper')),
                ),
                data: (path) {
                  if (path != null && File(path).existsSync()) {
                    return Image.file(File(path), fit: BoxFit.cover);
                  }
                  return ColoredBox(
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Text(
                        'Default wallpaper',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: colorScheme.primary),
            title: const Text('Choose from Gallery'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pick(context, ref),
          ),
          ListTile(
            leading: Icon(Icons.hide_image_outlined, color: colorScheme.primary),
            title: const Text('Remove Wallpaper'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _remove(context, ref),
          ),
          ListTile(
            leading: Icon(Icons.restart_alt_rounded, color: colorScheme.primary),
            title: const Text('Restore Default'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _remove(context, ref, message: 'Default wallpaper restored'),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    try {
      final file = await MediaPickerService.pickImageFromGallery();
      if (file == null) return;
      await ref.read(settingsRepositoryProvider).saveWallpaperFromFile(user.uid, file);
      ref.invalidate(chatWallpaperPathProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallpaper updated')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref, {
    String message = 'Wallpaper removed',
  }) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(settingsRepositoryProvider).removeWallpaper(user.uid);
      ref.invalidate(chatWallpaperPathProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
}

class ChatFontSizeSettingsScreen extends ConsumerWidget {
  const ChatFontSizeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizeAsync = ref.watch(chatFontSizeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final selected = sizeAsync.valueOrNull ?? ChatFontSizeOption.medium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Font Size'),
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
              side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final option in ChatFontSizeOption.values) ...[
                  ListTile(
                    title: Text(option.label),
                    subtitle: option == ChatFontSizeOption.medium
                        ? const Text('Default')
                        : null,
                    trailing: selected == option
                        ? Icon(Icons.check_rounded, color: colorScheme.primary)
                        : null,
                    onTap: () async {
                      final user = ref.read(currentUserProvider).valueOrNull;
                      if (user == null) return;
                      await ref
                          .read(settingsRepositoryProvider)
                          .setChatFontSize(user.uid, option);
                      ref.invalidate(chatFontSizeProvider);
                    },
                  ),
                  if (option != ChatFontSizeOption.large)
                    Divider(
                      height: 1,
                      indent: 16,
                      color: colorScheme.outline.withValues(alpha: 0.12),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Preview',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Hello from Velix',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16) *
                      selected.scale,
                ),
          ),
        ],
      ),
    );
  }
}

enum PrivacyField { lastSeen, profilePhoto }

class PrivacyOptionSettingsScreen extends ConsumerWidget {
  const PrivacyOptionSettingsScreen({
    super.key,
    required this.title,
    required this.field,
  });

  final String title;
  final PrivacyField field;

  static const lastSeen = PrivacyOptionSettingsScreen(
    title: 'Last Seen',
    field: PrivacyField.lastSeen,
  );

  static const profilePhoto = PrivacyOptionSettingsScreen(
    title: 'Profile Photo Visibility',
    field: PrivacyField.profilePhoto,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyAsync = ref.watch(privacySettingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final privacy = privacyAsync.valueOrNull ?? const PrivacySettings();
    final selected = field == PrivacyField.lastSeen
        ? privacy.lastSeen
        : privacy.profilePhoto;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
              side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final option in PrivacyVisibility.values) ...[
                  ListTile(
                    title: Text(option.label),
                    trailing: selected == option
                        ? Icon(Icons.check_rounded, color: colorScheme.primary)
                        : null,
                    onTap: () async {
                      final user = ref.read(currentUserProvider).valueOrNull;
                      if (user == null) return;
                      final next = field == PrivacyField.lastSeen
                          ? privacy.copyWith(lastSeen: option)
                          : privacy.copyWith(profilePhoto: option);
                      await ref
                          .read(settingsRepositoryProvider)
                          .updatePrivacySettings(user.uid, next);
                      ref.invalidate(privacySettingsProvider);
                    },
                  ),
                  if (option != PrivacyVisibility.nobody)
                    Divider(
                      height: 1,
                      indent: 16,
                      color: colorScheme.outline.withValues(alpha: 0.12),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

