import 'package:flutter/material.dart';

import '../features/splash/presentation/screens/splash_screen.dart';
import 'app_theme.dart';

class VelixApp extends StatelessWidget {
  const VelixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Velix',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}