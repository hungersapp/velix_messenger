import 'package:flutter/material.dart';

import 'app_pages.dart';
import 'app_theme.dart';

class VelixApp extends StatelessWidget {
  const VelixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Velix',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppPages.router,
    );
  }
}