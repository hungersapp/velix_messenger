import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/debug/nav_debug_log.dart';

/// Branded loading screen only.
/// Always continues to Login — no session / Google auto-login routing.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    navLog('Splash', 'initState');
    _continueToLogin();
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

  Future<void> _continueToLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) {
      navLog('Splash', 'context.mounted', {
        'mounted': false,
        'phase': 'after_delay',
      });
      return;
    }

    navLog('Splash', 'navigation start', {
      'destination': 'login',
      'goRouterLocation': goRouterLocationOf(context),
      'operation': 'context.go',
      'mounted': mounted,
    });

    context.go(AppRoutes.login);

    navLog('Splash', 'navigation end', {
      'destination': 'login',
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
