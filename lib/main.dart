import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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