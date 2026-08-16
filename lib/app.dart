import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
  Locale _locale = const Locale('fr');

  @override
  Widget build(BuildContext context) {
    return AppScope(
      themeMode: _themeMode,
      onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
      locale: _locale,
      onLocaleChanged: (loc) => setState(() => _locale = loc),
      child: MaterialApp.router(
        title: 'She4Tech Boutique',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _themeMode,
        locale: _locale,
        supportedLocales: const [Locale('fr'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: appRouter,
      ),
    );
  }
}
