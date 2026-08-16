import 'package:flutter/material.dart';

import '../widgets/app_scope.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Parametres')),
      body: ListView(
        children: [
          // Theme section
          _SectionHeader(title: 'Apparence'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Mode sombre'),
            subtitle: const Text('Activer le theme sombre'),
            value: scope.themeMode == ThemeMode.dark,
            onChanged: (dark) {
              scope.onThemeModeChanged(dark ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(),
          // Language section
          _SectionHeader(title: 'Langue'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Langue de l\'application'),
            trailing: SegmentedButton<Locale>(
              segments: const [
                ButtonSegment(
                  value: Locale('fr'),
                  label: Text('FR'),
                ),
                ButtonSegment(
                  value: Locale('en'),
                  label: Text('EN'),
                ),
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
          // Notifications section
          _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications push'),
            subtitle: const Text('Recevoir les alertes promotionnelles'),
            value: true,
            onChanged: (v) {},
          ),
          SwitchListTile(
            secondary: const Icon(Icons.email_outlined),
            title: const Text('Alertes email'),
            subtitle: const Text('Nouvelles offres et commandes'),
            value: false,
            onChanged: (v) {},
          ),
          const Divider(),
          // Privacy section
          _SectionHeader(title: 'Confidentialite'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Politique de confidentialite'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Supprimer mes donnees'),
            subtitle: const Text('Effacer toutes les donnees locales'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Confirmer la suppression'),
                  content: const Text(
                    'Toutes vos donnees locales seront effacees. Cette action est irreversible.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.error,
                      ),
                      child: const Text('Supprimer'),
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
