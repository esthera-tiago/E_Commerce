import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/app_scope.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.parametres)),
      body: ListView(
        children: [
          _SectionHeader(title: loc.apparence),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: Text(loc.modeSombre),
            subtitle: Text(loc.activerThemeSombre),
            value: scope.themeMode == ThemeMode.dark,
            onChanged: (dark) {
              scope.onThemeModeChanged(dark ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(),
          _SectionHeader(title: loc.langue),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(loc.langueApp),
            trailing: SegmentedButton<Locale>(
              segments: const [
                ButtonSegment(value: Locale('fr'), label: Text('FR')),
                ButtonSegment(value: Locale('en'), label: Text('EN')),
              ],
              selected: {scope.locale},
              onSelectionChanged: (selected) {
                if (selected.isNotEmpty) {
                  scope.onLocaleChanged(selected.first);
                }
              },
            ),
          ),
          const Divider(),
          _SectionHeader(title: loc.notifications),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(loc.notificationsPush),
            subtitle: Text(loc.recevoirAlertes),
            value: true,
            onChanged: (v) {},
          ),
          SwitchListTile(
            secondary: const Icon(Icons.email_outlined),
            title: Text(loc.alertesEmail),
            subtitle: Text(loc.nouvellesOffres),
            value: false,
            onChanged: (v) {},
          ),
          const Divider(),
          _SectionHeader(title: loc.confidentialite),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(loc.politiqueConfidentialite),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(loc.supprimerDonnees),
            subtitle: Text(loc.effacerDonnees),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(loc.confirmerSuppression),
                  content: Text(loc.texteSuppression),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(loc.annuler),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.error,
                      ),
                      child: Text(loc.supprimer),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
