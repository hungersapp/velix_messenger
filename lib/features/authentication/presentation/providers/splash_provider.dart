import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/secure_storage_providers.dart';
import '../../../../core/security/session_security_gate.dart';
import '../../../settings/presentation/providers/settings_feature_providers.dart';
import 'auth_provider.dart';

/// Where Splash should continue after checking the auth session.
enum SplashDestination {
  home,
  login,
  /// Persisted Firebase session exists but TOTP must be confirmed this process.
  needsTotp,
}

final splashProvider = Provider<SplashProvider>((ref) {
  return SplashProvider(ref);
});

class SplashProvider {
  SplashProvider(this.ref);

  final Ref ref;

  /// Uses the existing Firebase Auth session (no re-login).
  Future<SplashDestination> checkAppState() async {
    final secure = ref.read(secureStorageServiceProvider);
    final user =
        await ref.read(velixAuthServiceProvider).waitForRestoredSession();
    if (user == null) {
      SessionSecurityGate.clear();
      await secure.clearSessionBound();
      return SplashDestination.login;
    }

    await secure.setAuthSession(uid: user.uid);

    if (SessionSecurityGate.isSecondFactorVerified) {
      return SplashDestination.home;
    }

    // Prefer local TOTP flag to avoid a blocking Firestore round-trip.
    final cachedTotp = await secure.getTotpEnabled();
    final enabled = cachedTotp ??
        await ref.read(settingsRepositoryProvider).isTwoFactorEnabled(user.uid);

    if (cachedTotp == null) {
      // Warm cache for next cold start (non-critical if this fails).
      await secure.setTotpEnabled(enabled);
    } else {
      // Refresh cache in the background without blocking navigation.
      // ignore: discarded_futures, unawaited_futures
      () async {
        try {
          final fresh =
              await ref.read(settingsRepositoryProvider).isTwoFactorEnabled(
                    user.uid,
                  );
          await secure.setTotpEnabled(fresh);
        } catch (_) {}
      }();
    }

    if (!enabled) {
      SessionSecurityGate.markSecondFactorVerified();
      return SplashDestination.home;
    }

    return SplashDestination.needsTotp;
  }
}
