// ignore_for_file: avoid_print

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Activates Firebase App Check for Velix.
///
/// - **Debug builds (`kDebugMode`)**: Debug providers (register debug tokens
///   in Firebase Console for the *current* Android/iOS app id).
/// - **Profile / Release**: Play Integrity (Android) and App Attest with
///   DeviceCheck fallback (iOS).
///
/// Does not change authentication or business logic. Enforcement for
/// Firestore, Storage, and Auth is configured in the Firebase Console.
class VelixAppCheck {
  VelixAppCheck._();

  /// Debug-only: activate the debug provider and print the App Check token
  /// immediately (before UI). Call right after [Firebase.initializeApp].
  static Future<void> activateDebugAndPrintToken() async {
    assert(kDebugMode, 'activateDebugAndPrintToken is debug-only');

    print('====================================================');
    print('>>> APP CHECK: activating AndroidDebugProvider <<<');
    print('====================================================');

    if (kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        providerWeb: WebDebugProvider(),
      );
    } else {
      // Equivalent to legacy `androidProvider: AndroidProvider.debug`.
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidDebugProvider(),
        providerApple: const AppleDebugProvider(),
      );
    }

    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

    final appId = Firebase.app().options.appId;
    print('[VelixAppCheck] kDebugMode=$kDebugMode');
    print('[VelixAppCheck] providerAndroid=AndroidDebugProvider');
    print('[VelixAppCheck] appId=$appId');
    print(
      '[VelixAppCheck] Also watch logcat for '
      '"DebugAppCheckProvider: Enter this debug secret" — that UUID is what '
      'you register in Firebase Console → App Check → Manage debug tokens.',
    );

    try {
      final token = await FirebaseAppCheck.instance.getToken(true);
      print('====================================================');
      print('>>> APP CHECK DEBUG TOKEN: $token <<<');
      print('====================================================');
    } catch (e) {
      print('====================================================');
      print('App Check Token Fetch Error: $e');
      print('====================================================');
    }

    print('[VelixAppCheck] activate() completed successfully');
  }

  /// Profile / release activation. Debug builds should use
  /// [activateDebugAndPrintToken] (called from `main.dart`).
  static Future<void> activate() async {
    if (kDebugMode) {
      await activateDebugAndPrintToken();
      return;
    }

    if (kIsWeb) {
      return;
    }

    print('[VelixAppCheck] kDebugMode=$kDebugMode');
    print('[VelixAppCheck] providerAndroid=AndroidPlayIntegrityProvider');

    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidPlayIntegrityProvider(),
        providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );

      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

      try {
        final token = await FirebaseAppCheck.instance.getToken(true);
        print(
          '[VelixAppCheck] getToken(true) ok '
          '(${token == null || token.isEmpty ? 'empty' : 'ok'}).',
        );
      } catch (e) {
        print('[VelixAppCheck] getToken(true) exception: $e');
      }

      print('[VelixAppCheck] activate() completed successfully');
    } catch (e, st) {
      print('[VelixAppCheck] activate() failed: $e\n$st');
      rethrow;
    }
  }
}
