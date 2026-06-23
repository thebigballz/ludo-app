import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';

class LudoApp extends ConsumerWidget {
  const LudoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title:            'Ludo',
      debugShowCheckedModeBanner: false,
      theme:            AppTheme.dark,
      routerConfig:     router,
    );
  }
}