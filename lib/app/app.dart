import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_pages.dart';
import 'app_theme.dart';
import '../features/calling/presentation/widgets/incoming_call_host.dart';
import '../features/settings/presentation/providers/theme_mode_provider.dart';

class VelixApp extends ConsumerWidget {
  const VelixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Velix',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppPages.router,
      builder: (context, child) {
        return IncomingCallHost(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
