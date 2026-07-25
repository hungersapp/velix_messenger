import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Splash always continues to Login.
/// Velix session restore (skip Login when already signed in) lands in a later sprint.
enum SplashDestination {
  login,
}

/// Provider
final splashProvider = Provider<SplashProvider>((ref) {
  return SplashProvider(ref);
});

class SplashProvider {
  SplashProvider(this.ref);

  final Ref ref;

  Future<SplashDestination> checkAppState() async {
    return SplashDestination.login;
  }
}
