import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../profile/presentation/screens/profile_details_screen.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/entities/settings_models.dart';
import '../providers/settings_feature_providers.dart';
import '../providers/settings_toggles_provider.dart';
import '../providers/theme_mode_provider.dart';
import 'block_storage_devices_screens.dart';
import 'chat_and_privacy_settings_screens.dart';
import 'help_and_about_screens.dart';
import 'settings_theme_screen.dart';
import 'two_factor_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _appVersion = AboutVelixScreen.appVersion;
  static const _velixVersion = AboutVelixScreen.velixVersion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final messageNotifications =
        ref.watch(messageNotificationsEnabledProvider);
    final callNotifications = ref.watch(callNotificationsEnabledProvider);
    final privacyAsync = ref.watch(privacySettingsProvider);
    final bool readReceipts = privacyAsync.asData?.value.readReceipts ??
        ref.watch(readReceiptsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SettingsSection(
            title: 'Account',
            children: [
              _SettingsNavTile(
                icon: Icons.person_outline_rounded,
                title: 'Profile Details',
                onTap: () => _open(
                  context,
                  const ProfileDetailsScreen(),
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Appearance',
            children: [
              _SettingsNavTile(
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: _themeLabel(themeMode),
                onTap: () => _open(context, const SettingsThemeScreen()),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Chats',
            children: [
              _SettingsNavTile(
                icon: Icons.wallpaper_outlined,
                title: 'Chat Wallpaper',
                onTap: () =>
                    _open(context, const ChatWallpaperSettingsScreen()),
              ),
              _SettingsNavTile(
                icon: Icons.format_size_rounded,
                title: 'Font Size',
                onTap: () =>
                    _open(context, const ChatFontSizeSettingsScreen()),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Notifications',
            children: [
              _SettingsSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Message Notifications',
                value: messageNotifications,
                onChanged: (value) {
                  ref
                      .read(messageNotificationsEnabledProvider.notifier)
                      .state = value;
                },
              ),
              _SettingsSwitchTile(
                icon: Icons.call_outlined,
                title: 'Call Notifications',
                value: callNotifications,
                onChanged: (value) {
                  ref
                      .read(callNotificationsEnabledProvider.notifier)
                      .state = value;
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Privacy',
            children: [
              _SettingsNavTile(
                icon: Icons.schedule_outlined,
                title: 'Last Seen',
                subtitle: privacyAsync.valueOrNull?.lastSeen.label,
                onTap: () =>
                    _open(context, PrivacyOptionSettingsScreen.lastSeen),
              ),
              _SettingsNavTile(
                icon: Icons.photo_outlined,
                title: 'Profile Photo Visibility',
                subtitle: privacyAsync.valueOrNull?.profilePhoto.label,
                onTap: () =>
                    _open(context, PrivacyOptionSettingsScreen.profilePhoto),
              ),
              _SettingsSwitchTile(
                icon: Icons.done_all_rounded,
                title: 'Read Receipts',
                value: readReceipts,
                onChanged: (value) async {
                  ref.read(readReceiptsEnabledProvider.notifier).state = value;
                  final user = ref.read(currentUserProvider).valueOrNull;
                  if (user == null) return;
                  final current =
                      privacyAsync.valueOrNull ?? const PrivacySettings();
                  await ref
                      .read(settingsRepositoryProvider)
                      .updatePrivacySettings(
                        user.uid,
                        current.copyWith(readReceipts: value),
                      );
                  ref.invalidate(privacySettingsProvider);
                },
              ),
              _SettingsNavTile(
                icon: Icons.block,
                title: 'Blocked Users',
                onTap: () =>
                    _open(context, const BlockedUsersSettingsScreen()),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Storage & Data',
            children: [
              _SettingsNavTile(
                icon: Icons.storage_outlined,
                title: 'Storage Usage',
                onTap: () =>
                    _open(context, const StorageUsageSettingsScreen()),
              ),
              _SettingsNavTile(
                icon: Icons.download_outlined,
                title: 'Media Auto Download',
                onTap: () =>
                    _open(context, const MediaAutoDownloadSettingsScreen()),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Security',
            children: [
              _SettingsNavTile(
                icon: Icons.security_outlined,
                title: 'Two-Factor Authentication',
                onTap: () =>
                    _open(context, const TwoFactorSettingsScreen()),
              ),
              _SettingsNavTile(
                icon: Icons.devices_outlined,
                title: 'Active Devices',
                onTap: () {
                  ref.invalidate(activeDevicesProvider);
                  _open(context, const ActiveDevicesSettingsScreen());
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Help',
            children: [
              _SettingsNavTile(
                icon: Icons.help_outline_rounded,
                title: 'Help Center',
                onTap: () => _open(context, const HelpCenterScreen()),
              ),
              _SettingsNavTile(
                icon: Icons.support_agent_outlined,
                title: 'Contact Support',
                onTap: () => _open(context, const ContactSupportScreen()),
              ),
              _SettingsNavTile(
                icon: Icons.report_outlined,
                title: 'Report a Problem',
                onTap: () => _open(context, const ReportProblemScreen()),
              ),
              _SettingsNavTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => context.push(AppRoutes.privacy),
              ),
              _SettingsNavTile(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                onTap: () => context.push(AppRoutes.terms),
              ),
            ],
          ),
          _SettingsSection(
            title: 'About',
            children: [
              _SettingsNavTile(
                icon: Icons.info_outline_rounded,
                title: 'App Version',
                trailingLabel: _appVersion,
                onTap: () => _open(context, const AboutVelixScreen()),
              ),
              _SettingsNavTile(
                icon: Icons.verified_outlined,
                title: 'Velix Version',
                trailingLabel: _velixVersion,
                onTap: () => _open(context, const AboutVelixScreen()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Velix Messenger',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
  }

  static void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Material(
            color: colorScheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 12,
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

class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailingLabel,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailingLabel == null
          ? Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trailingLabel!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
      onTap: onTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      secondary: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
