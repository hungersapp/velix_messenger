import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/debug/nav_debug_log.dart';
import '../../../../core/security/session_security_gate.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../authentication/presentation/providers/splash_provider.dart';
import '../../../settings/presentation/providers/settings_feature_providers.dart';
import '../../../user/presentation/providers/current_user_provider.dart';

/// Branded splash that restores a persisted Firebase session when present.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// Brand hold — keep short so session restore is not artificially delayed.
  static const _minSplashDuration = Duration(milliseconds: 400);
  static const _maxSplashDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    navLog('Splash', 'initState');
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    navLog('Splash', 'didChangeDependencies', {
      'goRouterLocation': goRouterLocationOf(context),
      'mounted': mounted,
    });
  }

  @override
  void dispose() {
    navLog('Splash', 'dispose');
    super.dispose();
  }

  SplashDestination _destinationFromCurrentUser() {
    final user = ref.read(velixAuthServiceProvider).currentUser;
    if (user == null) return SplashDestination.login;
    if (SessionSecurityGate.isSecondFactorVerified) {
      return SplashDestination.home;
    }
    return SplashDestination.needsTotp;
  }

  Future<String?> _promptTotp() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Two-Factor Authentication'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Authenticator code',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _bootstrap() async {
    final stopwatch = Stopwatch()..start();

    var destination = await ref.read(splashProvider).checkAppState().timeout(
          _maxSplashDuration,
          onTimeout: _destinationFromCurrentUser,
        );

    final remaining = _minSplashDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted) {
      navLog('Splash', 'context.mounted', {
        'mounted': false,
        'phase': 'after_bootstrap',
      });
      return;
    }

    if (destination == SplashDestination.needsTotp) {
      final otp = await _promptTotp();
      if (!mounted) return;
      if (otp == null || otp.isEmpty) {
        await ref.read(authRepositoryProvider).signOut();
        destination = SplashDestination.login;
      } else {
        final ok =
            await ref.read(settingsRepositoryProvider).verifyLoginTotp(otp);
        if (!ok) {
          await ref.read(authRepositoryProvider).signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid authenticator code')),
            );
          }
          destination = SplashDestination.login;
        } else {
          SessionSecurityGate.markSecondFactorVerified();
          destination = SplashDestination.home;
        }
      }
    }

    if (!mounted) return;

    final route = destination == SplashDestination.home
        ? AppRoutes.home
        : AppRoutes.login;

    navLog('Splash', 'navigation start', {
      'destination': route,
      'goRouterLocation': goRouterLocationOf(context),
      'operation': 'context.go',
      'mounted': mounted,
    });

    if (destination == SplashDestination.home) {
      // Soft-refresh profile without forcing a full-screen loading flash.
      // ignore: unawaited_futures
      ref.read(currentUserProvider.notifier).refreshUser();
    }

    context.go(route);

    navLog('Splash', 'navigation end', {
      'destination': route,
      'goRouterLocation': mounted
          ? goRouterLocationOf(context)
          : 'unmounted',
      'mounted': mounted,
    });
  }

  @override
  Widget build(BuildContext context) {
    navLog('Splash', 'build', {
      'goRouterLocation': goRouterLocationOf(context),
      'mounted': mounted,
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              height: 140,
            ),
            const SizedBox(height: 24),
            const Text(
              'Velix',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fast. Secure. Simple.',
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
