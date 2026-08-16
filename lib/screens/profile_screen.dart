import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/user_provider.dart';
import '../widgets/adaptive_scaffold.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(editableUserProvider);
    final cs = Theme.of(context).colorScheme;

    return AdaptiveScaffold(
      title: 'Profil',
      currentIndex: 3,
      onDestinationSelected: (i) => _go(context, i),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _editAvatar(context, ref),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  user.name.isNotEmpty ? user.name[0] : '?',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Appuyez pour modifier',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _editProfile(context, ref, user),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier le profil'),
            ),
          ),
          const SizedBox(height: 24),
          _InfoTile(
            icon: Icons.calendar_today,
            label: 'Membre depuis',
            value: user.memberSince,
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.star_outline,
            label: 'Points fidelite',
            value: '${user.loyaltyPoints}',
          ),
          const SizedBox(height: 32),
          const Divider(),
          _ActionTile(
            icon: Icons.settings_outlined,
            title: 'Parametres',
            onTap: () => context.pushNamed('settings'),
          ),
          _ActionTile(
            icon: Icons.help_outline,
            title: 'Aide & contact',
            onTap: () => context.pushNamed('help'),
          ),
          _ActionTile(
            icon: Icons.info_outline,
            title: 'A propos',
            onTap: () => context.pushNamed('about'),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, int index) {
    const names = ['home', 'cart', 'favorites', 'profile'];
    if (index >= 0 && index < names.length) context.goNamed(names[index]);
  }

  void _editAvatar(BuildContext context, WidgetRef ref) {
    final user = ref.read(editableUserProvider);
    final initials = [
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
      'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    ];
    showModalBottomSheet(
      context: context,
      builder: (_) => _AvatarPicker(
        currentInitial: user.name.isNotEmpty ? user.name[0] : '?',
        initials: initials,
        onSelected: (initial) {
          ref.read(editableUserProvider.notifier).updateName(
                initial + user.name.substring(1),
              );
        },
      ),
    );
  }

  void _editProfile(BuildContext context, WidgetRef ref, dynamic user) {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Modifier le profil',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                if (name.isNotEmpty) {
                  ref.read(editableUserProvider.notifier).updateName(name);
                }
                if (email.isNotEmpty) {
                  ref.read(editableUserProvider.notifier).updateEmail(email);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil mis a jour')),
                );
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.currentInitial,
    required this.initials,
    required this.onSelected,
  });

  final String currentInitial;
  final List<String> initials;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choisir un avatar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: initials.map((letter) {
              final selected = letter == currentInitial;
              return GestureDetector(
                onTap: () {
                  onSelected(letter);
                  Navigator.pop(context);
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
