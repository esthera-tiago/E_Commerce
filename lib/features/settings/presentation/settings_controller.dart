import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/storage/json_cache_store.dart';

/// Préférences d'affichage persistées dans Hive.
class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system, this.locale});

  final ThemeMode themeMode;

  /// `null` = suivre la langue de l'appareil.
  final Locale? locale;

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool clearLocale = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }
}

/// Notifier Riverpod responsable du thème et de la langue.
class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._cache) : super(const AppSettings()) {
    _restore();
  }

  final JsonCacheStore _cache;

  static const _themeKey = 'settings_theme';
  static const _localeKey = 'settings_locale';

  /// Les préférences sont lues sans bloquer le premier rendu : l'application
  /// s'affiche immédiatement avec les valeurs par défaut puis se corrige.
  Future<void> _restore() async {
    final raw = await _cache.read<Map<String, dynamic>>('settings');
    if (raw == null) return;
    state = AppSettings(
      themeMode: _decodeTheme(raw[_themeKey]),
      locale: _decodeLocale(raw[_localeKey]),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _write(_themeKey, mode.name);
  }

  /// Choisir « Système » remet la langue à un suivi automatique.
  Future<void> setLocale(Locale? locale) async {
    state = state.copyWith(locale: locale, clearLocale: locale == null);
    if (locale == null) {
      await _cache.write(_localeKey, 'system');
    } else {
      await _cache.write(_localeKey, locale.languageCode);
    }
  }

  Future<void> _write(String key, String value) =>
      _cache.write('settings', {key: value}, merge: true);

  static ThemeMode _decodeTheme(Object? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static Locale? _decodeLocale(Object? value) => switch (value) {
    final String code when code != 'system' && code.isNotEmpty => Locale(code),
    _ => null,
  };
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
      return SettingsController(ref.watch(localStorageProvider).preferences);
    });

/// Chaînes localisées disponibles **hors** d'un `BuildContext`.
///
/// Les contrôleurs Riverpod ont besoin de traduire une `Failure`, mais ne
/// peuvent pas appeler `AppStrings.of(context)`. Ce provider dérive la locale
/// des préférences, ce qui garantit une source de vérité unique.
final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(
    settingsControllerProvider.select((settings) => settings.locale),
  );
  return AppStrings(locale ?? const Locale('fr'));
});
