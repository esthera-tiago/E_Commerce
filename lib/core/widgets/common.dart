import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import '../l10n/app_strings.dart';

/// Bandeau « hors-ligne » affiché en haut de l'application.
///
/// Le repository sert déjà des données en cache ; ce bandeau explique à
/// l'utilisateur **pourquoi** il voit d'anciennes données, ce qui évite
/// qu'il interprète l'affichage comme un bug.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      child: isOffline
          ? Material(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 18,
                      color: scheme.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        strings.offlineBanner,
                        style: TextStyle(
                          color: scheme.onErrorContainer,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(width: double.infinity, height: 0),
    );
  }
}

/// Plafond de décodage, en pixels physiques. Au-delà, le gain de netteté est
/// invisible et le coût mémoire devient absurde.
const int maxDecodeWidth = 2048;

/// Image distante avec états de chargement et de repli.
///
/// `CachedNetworkImage` est indispensable ici : il sert le fichier depuis le
/// cache disque, ce qui rend les visuels disponibles hors-ligne. Le repli
/// évite l'icône cassée quand l'API renvoie une URL vide.
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    required this.url,
    super.key,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.semanticLabel,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Nom de l'image pour les lecteurs d'écran. Laisser `null` la rend
  /// muette : c'est le bon choix quand l'image répète une information déjà
  /// annoncée par du texte voisin, comme la vignette d'une tuile produit.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.image_not_supported_outlined, color: scheme.outline),
    );

    if (url.isEmpty) return placeholder;

    // Décoder à la taille d'affichage plutôt qu'en pleine résolution : une
    // vignette de catalogue servie en 400 px n'a aucune raison d'occuper
    // 2000 px de mémoire vive. `LayoutBuilder` donne la largeur réellement
    // allouée, `devicePixelRatio` la densité cible, et le plafond évite
    // d'allouer un bitmap déraisonnable sur un écran très dense.
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final width = constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
        final memCacheWidth = width <= 0
            ? null
            : (width * dpr).round().clamp(1, maxDecodeWidth);

        final Widget image = CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          memCacheWidth: memCacheWidth,
          placeholder: (_, _) => ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  semanticsLabel: strings.loading,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          errorWidget: (_, _, _) => placeholder,
        );

        // Un nom unique remplace l'annonce interne de l'image : `excludeSemantics`
        // empêche la lecture de « Chargement… » puis du nom en double.
        final Widget content = semanticLabel == null
            ? image
            : Semantics(
                label: semanticLabel,
                image: true,
                excludeSemantics: true,
                child: image,
              );

        if (borderRadius == null) return content;
        return ClipRRect(borderRadius: borderRadius!, child: content);
      },
    );
  }
}

/// Affichage compact d'une note sur 5.
class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    super.key,
    this.size = 16,
    this.showValue = true,
  });

  final double rating;
  final double size;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Les cinq étoiles sont un motif visuel : sans `excludeSemantics`, un
    // lecteur d'écran annonce « étoile » cinq fois avant d'annoncer la note.
    return Semantics(
      label: AppStrings.of(context).rating(rating),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              rating >= i
                  ? Icons.star_rounded
                  : (rating >= i - 0.5
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded),
              size: size,
              color: rating >= i - 0.5
                  ? const Color(0xFFF5A623)
                  : scheme.outlineVariant,
            ),
          if (showValue) ...[
            const SizedBox(width: 6),
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: size * 0.85,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Vue d'erreur avec action « Réessayer ».
///
/// Le message est déjà traduit par le contrôleur : l'écran ne fait que
/// l'afficher, ce qui centralise la traduction dans une seule table.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(strings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// État vide illustré, réutilisé par le panier, les favoris et les commandes.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              // L'icône ne fait qu'illustrer le message qui suit.
              // `Icon` sans `semanticLabel` est déjà muet : l'icône ne fait
              // qu'illustrer le message qui suit.
              child: Icon(icon, size: 40, color: scheme.outline),
            ),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
