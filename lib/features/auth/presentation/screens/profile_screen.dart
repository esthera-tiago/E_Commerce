import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/common.dart';
import '../auth_controller.dart';

/// Profil de l'utilisateur connecté.
///
/// Les données proviennent de `GET /users/{id}` et sont rafraîchies à la
/// demande ; hors-ligne, le repository restitue la fiche en cache.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({required this.onOpenOrders, super.key});

  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final state = ref.watch(authControllerProvider);
    final user = state.user;
    final scheme = Theme.of(context).colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.profile)),
        body: EmptyState(icon: Icons.person_outline, title: strings.guest),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.myAccount),
        actions: [
          IconButton(
            tooltip: strings.refreshProfile,
            onPressed: ref.read(authControllerProvider.notifier).refreshProfile,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: strings.logout,
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: scheme.primaryContainer,
                          child: user.avatarUrl.isEmpty
                              ? Text(
                                  user.initials,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                )
                              : ClipOval(
                                  child: RemoteImage(
                                    url: user.avatarUrl,
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@${user.username}',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _InfoTile(
                  icon: Icons.alternate_email,
                  label: strings.email,
                  value: user.email,
                ),
                _InfoTile(
                  icon: Icons.badge_outlined,
                  label: strings.username,
                  value: user.username,
                ),
                if (user.gender.isNotEmpty)
                  _InfoTile(
                    icon: Icons.wc,
                    label: strings.profile,
                    value: user.gender,
                  ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(strings.orders),
                    subtitle: Text(strings.connectedApi),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onOpenOrders,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.apiAccount,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
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
    final scheme = Theme.of(context).colorScheme;
    if (value.isEmpty) return const SizedBox.shrink();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
      subtitle: Text(value, style: const TextStyle(fontSize: 15)),
    );
  }
}
