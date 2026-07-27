import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../providers/my_profile_provider.dart';
import '../widgets/profile_action_tile.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/qr_identity_card.dart';
import '../widgets/velix_id_card.dart';
import 'my_velix_qr_screen.dart';
import 'profile_details_screen.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(currentUserProvider);
    if (!context.mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(myProfileProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 600 ? 48.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: identityAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Unable to load profile.',
              style: theme.textTheme.bodyLarge,
            ),
          ),
          data: (identity) {
            if (identity == null) {
              return Center(
                child: Text(
                  'Sign in to view your profile.',
                  style: theme.textTheme.bodyLarge,
                ),
              );
            }

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ProfileAvatar(
                          displayName: identity.displayName,
                          photoUrl: identity.photoUrl,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        identity.displayName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        identity.handle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const MyVelixQrScreen(),
                              ),
                            );
                          },
                          child: QrIdentityCard(velixId: identity.handle),
                        ),
                      ),
                      const SizedBox(height: 28),
                      VelixIdCard(identity: identity),
                      const SizedBox(height: 16),
                      ProfileActionTile(
                        title: 'Profile Details',
                        icon: Icons.person_outline_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ProfileDetailsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      ProfileActionTile(
                        title: 'Settings',
                        icon: Icons.settings_outlined,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () => _logout(context, ref),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
