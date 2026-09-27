import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/common.dart';
import '../cart_controller.dart';

/// Panier local : ajout, incrémentation, suppression et récapitulatif.
///
/// Le total est recalculé à partir des prix remis appliqués par l'entité
/// `Product`, afin que l'affichage reste cohérent avec le catalogue.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final cart = ref.watch(cartControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(cartControllerProvider.notifier);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.cart)),
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: strings.cartEmpty,
          subtitle: strings.cartEmptyHint,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.cart),
        actions: [
          IconButton(
            tooltip: strings.clearCart,
            onPressed: () {
              controller.clear();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(strings.cartCleared)));
            },
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: cart.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: RemoteImage(
                          url: item.product.thumbnail,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.price(item.product.discountedPrice),
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _QuantityStepper(
                              quantity: item.quantity,
                              onIncrement: () => controller.add(item.product),
                              onDecrement: () =>
                                  controller.decrement(item.product),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: strings.remove,
                        onPressed: () => controller.remove(item.product),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _SummaryBar(cart: cart, strings: strings),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            onPressed: onDecrement,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            onPressed: onIncrement,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _SummaryBar extends ConsumerWidget {
  const _SummaryBar({required this.cart, required this.strings});

  final CartState cart;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings.itemsCount(cart.itemCount),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${strings.total} : ${strings.price(cart.subtotal)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _confirm(context, ref),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(strings.checkout),
            ),
          ],
        ),
      ),
    );
  }

  /// La commande étant locale, la confirmation vide le panier après avoir
  /// capturé son contenu pour l'écran de remerciement.
  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.checkout),
        content: Text('${strings.total} : ${strings.price(cart.subtotal)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.remove),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.checkout),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    ref.read(cartControllerProvider.notifier).checkout();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, size: 48),
        title: Text(strings.orderPlaced),
        content: Text(strings.thanksForYourOrder),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.checkout),
          ),
        ],
      ),
    );
  }
}
