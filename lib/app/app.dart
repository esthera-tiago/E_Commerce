import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/presentation/settings_controller.dart';
import 'router/app_router.dart';

/// Racine de l'application : thème, langue et routeur sont pilotés par les
/// préférences persistées, et la session determine l'écran affiché.
class ECommerceApp extends ConsumerWidget {
  const ECommerceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'She4Tech',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: router,
      locale: settings.locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        // Indispensable : sans ces délégués, `MaterialApp` ne fournit que
        // `DefaultMaterialLocalizations`, qui ne parle qu'anglais. Les widgets
        // Material (champs de saisie, infobulles, sélecteurs de date, menus de
        // collé) lèvent alors « No MaterialLocalizations found » sur tout
        // appareil dont la langue est le français.
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // `MediaQuery.textScaler` est borné pour qu'un réglage d'accessibilité
        // extrême ne casse pas les mises en page à grille fixe.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
