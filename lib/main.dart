// ignore_for_file: avoid_print

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/security/secure_storage_service.dart';
import 'core/security/velix_app_check.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parallelize non-dependent startup work to shorten time-to-first-frame.
  final secureStorage = SecureStorageService();
  final migration = secureStorage.migrateFromLegacyPrefs();
  final firebase = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Future.wait<void>([migration, firebase]);

  // App Check must activate after Firebase.initializeApp and before
  // navigation / UI so the debug token is printed before any Storage traffic.
  if (kDebugMode) {
    // Explicit debug activation (AndroidDebugProvider == AndroidProvider.debug).
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider(),
    );
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    try {
      final token = await FirebaseAppCheck.instance.getToken(true);
      print('====================================================');
      print('>>> APP CHECK DEBUG TOKEN: $token <<<');
      print('====================================================');
    } catch (e) {
      print('App Check Token Fetch Error: $e');
    }
    print(
      '[VelixAppCheck] Watch logcat for DebugAppCheckProvider '
      '"Enter this debug secret" — register that UUID for app.velix.messenger.',
    );
  } else {
    await VelixAppCheck.activate();
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint(details.exceptionAsString());
    debugPrint(details.stack.toString());
  };

  runApp(
    const ProviderScope(
      child: VelixApp(),
    ),
  );
}
