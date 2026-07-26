import 'package:flutter/material.dart';

import 'app_pages.dart';
import 'app_theme.dart';
import '../features/calling/presentation/widgets/incoming_call_host.dart';

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
      builder: (context, child) {
        return IncomingCallHost(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
