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
    final cartQuantity = ref
        .watch(cartControllerProvider)
        .quantityOf(product.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  // Légèrement moins carré que la tuile : l'image reste
                  // dominante sans rogner la place du titre et des prix.
                  aspectRatio: 1.15,
                  child: RemoteImage(url: product.thumbnail),
                ),
                if (product.isOnDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _Badge(
                      label:
                          '-${product.discountPercentage.toStringAsFixed(0)}%',
                      background: scheme.error,
                      foreground: scheme.onError,
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    tooltip: strings.favorites,
                    onPressed: () => ref
                        .read(favoritesControllerProvider.notifier)
                        .toggle(product),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? scheme.error : null,
                    ),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    RatingStars(rating: product.rating, size: 14),
                    const SizedBox(height: 6),
                    // La hauteur de la carte est fixe : les deux prix doivent
                    // rester sur une seule ligne. `Flexible` + troncature
                    // évitent le débordement horizontal sur les petits montants
                    // étroits, là où un `Wrap` ajouterait une ligne et ferait
                    // déborder la colonne verticalement.
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            strings.price(product.discountedPrice),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
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
        ),
      ),
    );
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
