import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/favorites_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoritesProvider);
    final productsAsync = ref.watch(productListProvider);

    return AdaptiveScaffold(
      title: 'Favoris',
      currentIndex: 2,
      onDestinationSelected: (i) => _go(context, i),
      body: productsAsync.when(
        data: (products) {
          final favProducts =
              products.where((p) => favIds.contains(p.id)).toList();

          if (favProducts.isEmpty) {
            return const Center(
              child: Text('Aucun favori pour le moment.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: favProducts.length,
            itemBuilder: (_, i) => SizedBox(
              height: 260,
              child: ProductCard(product: favProducts[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  void _go(BuildContext context, int index) {
    const names = ['home', 'cart', 'favorites', 'profile'];
    if (index >= 0 && index < names.length) context.goNamed(names[index]);
  }
}
