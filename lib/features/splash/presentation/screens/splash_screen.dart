import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/screens/login_screen.dart';
import '../../../authentication/presentation/providers/splash_provider.dart';
import '../../../auth/presentation/screens/first_user_entry_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends ConsumerState<SplashScreen> {

  @override
  void initState() {
    super.initState();

    _checkAppState();
  }

  Future<void> _checkAppState() async {

    // Splash Logo 2 Seconds
    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    final destination = await ref
        .read(splashProvider)
        .checkAppState();

    if (!mounted) return;

    switch (destination) {

      case SplashDestination.login:

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
        break;

      case SplashDestination.home:

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
        break;

      case SplashDestination.firstUser:

        final firebaseUser =
            FirebaseAuth.instance.currentUser!;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FirstUserEntryScreen(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              name: firebaseUser.displayName ?? '',
              photoUrl: firebaseUser.photoURL ?? '',
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
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