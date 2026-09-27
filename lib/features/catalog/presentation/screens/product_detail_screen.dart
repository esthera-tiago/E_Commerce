import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/common.dart';
import '../../../cart/presentation/cart_controller.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_review.dart';
import '../catalog_controller.dart';

/// Fiche produit détaillée : galerie, description, avis et ajout au panier.
///
/// Le produit vient de `GET /products/{id}`, qui renvoie les avis imbriqués ;
/// il n'existe pas de route d'avis séparée sur cette API.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final async = ref.watch(productDetailProvider(productId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Scaffold(
          appBar: AppBar(),
          body: ErrorView(
            message: strings.errorGeneric,
            onRetry: () => ref.invalidate(productDetailProvider(productId)),
          ),
        ),
        data: (product) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: RemoteImage(url: product.thumbnail),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.brand.isEmpty
                              ? product.category
                              : product.brand,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: scheme.primary),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: strings.favorites,
                        onPressed: () => ref
                            .read(favoritesControllerProvider.notifier)
                            .toggle(product),
                        icon: Icon(
                          ref.watch(isFavoriteProvider(product.id))
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: ref.watch(isFavoriteProvider(product.id))
                              ? scheme.error
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      RatingStars(rating: product.rating, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '${product.reviews.length} ${strings.reviews.toLowerCase()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // `Wrap` : sur un écran étroit, le prix barré et la pastille
                  // de réduction ne tiennent pas sur une ligne avec le prix
                  // principal. L'écran défile, la hauteur n'est pas contrainte.
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Text(
                        strings.price(product.discountedPrice),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (product.isOnDiscount) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            strings.price(product.price),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  decoration: TextDecoration.lineThrough,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${product.discountPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: scheme.onErrorContainer,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  _StockLine(product: product, strings: strings),
                  const SizedBox(height: 22),
                  _Section(
                    title: strings.description,
                    child: Text(product.description),
                  ),
                  if (product.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in product.tags)
                          Chip(
                            label: Text(tag),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  _SpecRow(label: strings.brand, value: product.brand),
                  _SpecRow(label: strings.sku, value: product.sku),
                  _SpecRow(
                    label: strings.shipping,
                    value: product.shippingInformation,
                  ),
                  _SpecRow(
                    label: strings.warranty,
                    value: product.warrantyInformation,
                  ),
                  const SizedBox(height: 22),
                  _Section(
                    title: '${strings.reviews} (${product.reviews.length})',
                    child: product.reviews.isEmpty
                        ? Text(
                            strings.noReviews,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          )
                        : Column(
                            children: [
                              for (final review in product.reviews)
                                _ReviewTile(review: review, strings: strings),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (product) => _AddToCartBar(product: product, strings: strings),
        orElse: () => null,
      ),
    );
  }
}

class _AddToCartBar extends ConsumerWidget {
  const _AddToCartBar({required this.product, required this.strings});

  final Product product;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final quantity = ref.watch(cartControllerProvider).quantityOf(product.id);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            if (quantity > 0) ...[
              Icon(Icons.shopping_bag, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                '$quantity',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: FilledButton.icon(
                onPressed: product.isInStock
                    ? () {
                        ref.read(cartControllerProvider.notifier).add(product);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(strings.addedToCart),
                              duration: const Duration(milliseconds: 1400),
                            ),
                          );
                      }
                    : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(
                  product.isInStock ? strings.addToCart : strings.outOfStock,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockLine extends StatelessWidget {
  const _StockLine({required this.product, required this.strings});

  final Product product;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!product.isInStock) {
      return Text(
        strings.outOfStock,
        style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
      );
    }
    if (product.isLowStock) {
      return Text(
        '${strings.lowStock} — ${product.stock}',
        style: TextStyle(color: scheme.tertiary, fontWeight: FontWeight.w600),
      );
    }
    return Text(
      '${product.stock} ${strings.itemsCount(product.stock)}',
      style: TextStyle(color: scheme.onSurfaceVariant),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.strings});

  final ProductReview review;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RatingStars(rating: review.rating, size: 14),
              const SizedBox(width: 8),
              Text(
                review.reviewerName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            review.comment,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
