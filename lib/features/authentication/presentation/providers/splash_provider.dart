import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_dependency_provider.dart';

/// Splash Navigation Destination
enum SplashDestination {
  login,
  firstUser,
  home,
}

/// Provider
final splashProvider =
    Provider<SplashProvider>((ref) {
  return SplashProvider(ref);
});

class SplashProvider {
  SplashProvider(this.ref);

  final Ref ref;

  Future<SplashDestination> checkAppState() async {
    // Check Firebase Login
    final firebaseUser =
        FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return SplashDestination.login;
    }

    // Check Firestore User
    final getUser =
        ref.read(getUserUseCaseProvider);

    final user =
        await getUser(firebaseUser.uid);

    if (user == null) {
      return SplashDestination.firstUser;
    }

    return SplashDestination.home;
  }
}