import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/user_provider.dart';
import '../widgets/adaptive_scaffold.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final cs = Theme.of(context).colorScheme;

    return AdaptiveScaffold(
      title: 'Profil',
      currentIndex: 3,
      onDestinationSelected: (i) => _go(context, i),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
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
          const SizedBox(height: 32),
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
