import 'package:flutter/material.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required super.child,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  static AppScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScope>()!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      themeMode != oldWidget.themeMode;
}
