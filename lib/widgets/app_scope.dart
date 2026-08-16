import 'package:flutter/material.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.locale,
    required this.onLocaleChanged,
    required super.child,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  static AppScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScope>()!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      themeMode != oldWidget.themeMode || locale != oldWidget.locale;
}
