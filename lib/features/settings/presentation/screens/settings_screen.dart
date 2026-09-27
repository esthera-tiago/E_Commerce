import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/common.dart';
import '../settings_controller.dart';

/// Préférences d'affichage et gestion du cache local.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    required this.onOpenHelp,
    required this.onOpenAbout,
    super.key,
  });

  final VoidCallback onOpenHelp;
  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        children: [
          const OfflineBanner(),
          _SectionHeader(strings.appearance),
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (mode) {
              if (mode != null) controller.setThemeMode(mode);
            },
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text(strings.themeSystem),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text(strings.themeLight),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text(strings.themeDark),
                ),
              ],
            ),
          ),
          const Divider(),
          _SectionHeader(strings.language),
          RadioGroup<String>(
            groupValue: settings.locale?.languageCode ?? 'system',
            onChanged: (code) => controller.setLocale(
              code == null || code == 'system' ? null : Locale(code),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'system',
                  title: Text(strings.themeSystem),
                ),
                const RadioListTile<String>(
                  value: 'fr',
                  title: Text('Français'),
                ),
                const RadioListTile<String>(
                  value: 'en',
                  title: Text('English'),
                ),
              ],
            ),
          ),
          const Divider(),
          _SectionHeader(strings.dataAndPrivacy),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: Text(strings.clearCache),
            subtitle: Text(
              strings.cacheHint,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            onTap: () async {
              final storage = ref.read(localStorageProvider);
              final repository = ref.read(catalogRepositoryProvider);
              await Future.wait([storage.clearAll(), repository.clearCache()]);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(strings.cacheCleared)));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(strings.help),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenHelp,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(strings.about),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenAbout,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: scheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
