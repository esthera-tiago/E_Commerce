import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/filter_bar.dart';
import '../widgets/product_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(filteredProductsProvider);
    final itemCount = ref.watch(cartItemCountProvider);

    return AdaptiveScaffold(
      title: 'Boutique',
      currentIndex: 0,
      onDestinationSelected: (i) => _go(context, i),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_outline),
          onPressed: () => context.pushNamed('favorites'),
        ),
        Badge(
          isLabelVisible: itemCount > 0,
          label: Text('$itemCount'),
          child: IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.pushNamed('cart'),
          ),
        ),
      ],
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: FilterBar()),
          ref.watch(productListProvider).when(
                data: (_) => products.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Text('Aucun produit trouve.'),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(12),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.55,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => ProductCard(product: products[i]),
                            childCount: products.length,
                          ),
                        ),
                      ),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(
                    child: Text('Erreur de chargement: $e'),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  void _go(BuildContext context, int index) {
    const names = ['home', 'cart', 'favorites', 'profile'];
    if (index >= 0 && index < names.length) {
      context.goNamed(names[index]);
    }
  }
}
