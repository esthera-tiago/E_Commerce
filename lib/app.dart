import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'widgets/app_scope.dart';

class ECommerceApp extends StatefulWidget {
  const ECommerceApp({super.key});

  @override
  State<ECommerceApp> createState() => _ECommerceAppState();
}

class _ECommerceAppState extends State<ECommerceApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _onThemeModeChanged(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      themeMode: _themeMode,
      onThemeModeChanged: _onThemeModeChanged,
      child: MaterialApp.router(
        title: 'She4Tech Boutique',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _themeMode,
        routerConfig: appRouter,
      ),
    );
  }
}
