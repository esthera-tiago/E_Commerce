import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_provider.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/cart_item_tile.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return AdaptiveScaffold(
      title: 'Panier',
      currentIndex: 1,
      onDestinationSelected: (i) => _go(context, i),
      body: items.isEmpty
          ? const Center(
              child: Text('Votre panier est vide.'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => Dismissible(
                      key: ValueKey(items[i].product.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onError,
                        ),
                      ),
                      onDismissed: (_) {
                        ref
                            .read(cartProvider.notifier)
                            .remove(items[i].product.id);
                      },
                      child: CartItemTile(item: items[i]),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor.withAlpha(50),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              '${total.toStringAsFixed(2)} €',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: items.isEmpty
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Commande passee (simulation)'),
                                  ),
                                );
                                ref.read(cartProvider.notifier).clear();
                              },
                        icon: const Icon(Icons.check),
                        label: const Text('Commander'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _go(BuildContext context, int index) {
    const names = ['home', 'cart', 'favorites', 'profile'];
    if (index >= 0 && index < names.length) context.goNamed(names[index]);
  }
}
