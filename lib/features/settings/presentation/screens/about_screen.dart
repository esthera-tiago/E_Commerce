import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/app_strings.dart';

/// Fiche « à propos » : identité, pile technique et endpoint API.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const packageVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(strings.about)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.storefront,
                  size: 44,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                strings.appName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.tagline,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                '${strings.version} $packageVersion',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _TechCard(strings: strings),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: Text(strings.apiTitle),
              subtitle: Text(
                AppConfig.apiBaseUrl,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.wifi_off_outlined),
              title: Text(strings.offlineMode),
              subtitle: Text(
                strings.offlineBanner,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechCard extends StatelessWidget {
  const _TechCard({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const stack = [
      'Flutter & Dart',
      'Riverpod — injection de dépendances',
      'Dio — client HTTP et intercepteurs',
      'Hive CE — cache et préférences locales',
      'GoRouter — navigation déclarative',
      'Connectivity+ — détection hors-ligne',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.layers_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Text(
                  strings.techStack,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in stack)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•', style: TextStyle(color: scheme.primary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
