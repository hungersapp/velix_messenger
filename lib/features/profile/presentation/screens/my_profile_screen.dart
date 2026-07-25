import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/profile_localizations.dart';
import '../providers/my_profile_provider.dart';
import '../widgets/profile_action_tile.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/qr_identity_card.dart';
import '../widgets/velix_id_card.dart';
import 'my_velix_qr_screen.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(myProfileProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = ProfileLocalizations.of(context);
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
                      const SizedBox(height: 16),
                      Text(
                        l10n.slogan,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 28),
                      VelixIdCard(identity: identity),
                      const SizedBox(height: 16),
                      ProfileActionTile(
                        title: 'Profile Details',
                        icon: Icons.person_outline_rounded,
                        onTap: () {
                          // TODO: Profile Details screen
                        },
                      ),
                      const SizedBox(height: 12),
                      ProfileActionTile(
                        title: 'My Velix QR',
                        icon: Icons.qr_code_2_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MyVelixQrScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () {
                          // TODO: Logout
                        },
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
