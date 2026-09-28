import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/common.dart';
import '../../../cart/presentation/cart_controller.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../domain/entities/product.dart';

/// Tuile produit de la grille du catalogue.
class ProductCard extends ConsumerWidget {
  const ProductCard({required this.product, required this.onTap, super.key});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isFavorite = ref.watch(isFavoriteProvider(product.id));
    // `select` : la tuile ne se reconstruit que si *sa* quantité change.
    // Sans lui, le moindre ajout au panier reconstruisait toute la grille.
    final cartQuantity = ref.watch(
      cartControllerProvider.select((state) => state.quantityOf(product.id)),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Le contenu visuel est muet : il est entièrement repris par
          // l announcing unique posé plus bas. Sans cela, le lecteur d'écran
          // énumérait la marque, le nom, la note, le prix puis le prix barré
          // comme des éléments sans rapport, et annonçait « Chargement… »
          // pour la vignette.
          ExcludeSemantics(child: _visual(context, scheme, cartQuantity)),
          // Couche cliquable : un seul nœud, portant tout ce qui décrit le
          // produit. `MergeSemantics` sur les enfants n'aurait pas suffi —
          // le parent `InkWell` reste un nœud distinct, sans nom.
          Positioned.fill(
            child: Semantics(
              container: true,
              button: true,
              label: _label(strings, cartQuantity),
              child: InkWell(onTap: onTap, child: const SizedBox.expand()),
            ),
          ),
          // Le favori reste une cible distincte, au-dessus de la couche
          // cliquable : le fusionner aurait supprimé sa propre action.
          Positioned(
            top: 4,
            right: 4,
            child: _favoriteButton(context, ref, isFavorite),
          ),
        ],
      ),
    );
  }

  Widget _visual(BuildContext context, ColorScheme scheme, int cartQuantity) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            AspectRatio(
              // Légèrement moins carrée que la tuile : l'image reste
              // dominante sans rogner la place du titre et des prix.
              aspectRatio: 1.15,
              child: RemoteImage(url: product.thumbnail),
            ),
            if (product.isOnDiscount)
              Positioned(
                top: 8,
                left: 8,
                child: _Badge(
                  label: '-${product.discountPercentage.toStringAsFixed(0)}%',
                  background: scheme.error,
                  foreground: scheme.onError,
                ),
              ),
            if (cartQuantity > 0)
              Positioned(
                left: 8,
                bottom: 8,
                child: _Badge(
                  label: '$cartQuantity',
                  background: scheme.primary,
                  foreground: scheme.onPrimary,
                ),
              ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                RatingStars(rating: product.rating, size: 14),
                const SizedBox(height: 6),
                // La hauteur de la carte est fixe : les deux prix doivent
                // rester sur une seule ligne. `Flexible` + troncature évitent
                // le débordement horizontal sur les petits montants étroits,
                // là où un `Wrap` ajouterait une ligne et ferait déborder la
                // colonne verticalement.
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        strings.price(product.discountedPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (product.isOnDiscount) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          strings.price(product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                decoration: TextDecoration.lineThrough,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _favoriteButton(BuildContext context, WidgetRef ref, bool isFavorite) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      tooltip: isFavorite
          ? strings.removeFromFavorites
          : strings.addToFavorites,
      onPressed: () =>
          ref.read(favoritesControllerProvider.notifier).toggle(product),
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? scheme.error : null,
      ),
    );
  }

  /// Annonce unique de la tuile : c'est elle que le lecteur d'écran énonce,
  /// dans cet ordre, au lieu de lire la vignette puis chaque prix.
  String _label(AppStrings strings, int cartQuantity) {
    final parts = <String>[
      if (product.brand.isNotEmpty) product.brand,
      product.title,
      strings.rating(product.rating),
      if (product.isOnDiscount)
        '-${product.discountPercentage.toStringAsFixed(0)}%',
      strings.price(product.discountedPrice),
      if (cartQuantity > 0) '${strings.inCart} : $cartQuantity',
    ];
    return parts.join(', ');
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
