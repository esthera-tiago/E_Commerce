import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';

class CartItemTile extends ConsumerWidget {
  const CartItemTile({super.key, required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail placeholder
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: cs.primary.withAlpha(100),
              ),
            ),
            const SizedBox(width: 12),
            // Name + price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.product.price.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            // Quantity controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  iconSize: 18,
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => ref
                      .read(cartProvider.notifier)
                      .updateQuantity(item.product.id, item.quantity - 1),
                ),
                Text(
                  '${item.quantity}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  iconSize: 18,
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => ref
                      .read(cartProvider.notifier)
                      .updateQuantity(item.product.id, item.quantity + 1),
                ),
              ],
            ),
            const SizedBox(width: 4),
            // Total for this line
            Text(
              '${item.totalPrice.toStringAsFixed(2)} €',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
