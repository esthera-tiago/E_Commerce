import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/common.dart';
import '../favorites_controller.dart';

/// Liste des produits mis en favori.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({required this.onOpenProduct, super.key});

  final void Function(int productId) onOpenProduct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final favorites = ref.watch(favoriteProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: Text(strings.favorites)),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: favorites.when(
              loading: () => Center(
                child: CircularProgressIndicator(
                  semanticsLabel: strings.loading,
                ),
              ),
              error: (error, _) => ErrorView(
                message: strings.errorGeneric,
                onRetry: () => ref.invalidate(favoriteProductsProvider),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return EmptyState(
                    icon: Icons.favorite_border,
                    title: strings.favoritesEmpty,
                    subtitle: strings.favoritesEmptyHint,
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Column(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => onOpenProduct(product.id),
                            borderRadius: BorderRadius.circular(14),
                            child: RemoteImage(
                              url: product.thumbnail,
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          strings.price(product.discountedPrice),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
