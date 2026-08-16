import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isFav =
        ref.watch(favoritesProvider.select((s) => s.contains(product.id)));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          'productDetail',
          pathParameters: {'id': product.id},
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: cs.surfaceContainerHigh,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: cs.surfaceContainerHigh,
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 40,
                        color: cs.primary.withAlpha(80),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton(
                      iconSize: 20,
                      style: IconButton.styleFrom(
                        backgroundColor: cs.surface.withAlpha(200),
                      ),
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : cs.onSurfaceVariant,
                      ),
                      onPressed: () =>
                          ref.read(favoritesProvider.notifier).toggle(product.id),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.star, size: 13, color: Colors.amber[600]),
                      const SizedBox(width: 3),
                      Text(
                        '${product.rating}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${product.price.toStringAsFixed(2)} €',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                        ),
                      ),
                      IconButton(
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.add_shopping_cart, color: cs.primary),
                        onPressed: () {
                          ref.read(cartProvider.notifier).add(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} ajoute au panier'),
                              duration: const Duration(milliseconds: 800),
                            ),
                          );
                        },
                      ),
                    ],
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
