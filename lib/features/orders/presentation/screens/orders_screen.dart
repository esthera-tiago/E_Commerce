import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../domain/entities/order.dart';
import '../orders_provider.dart';

/// Historique des paniers du compte connecté (`GET /carts/user/{id}`).
///
/// Chaque ligne contient le détail de la commande, ses quantités et son
/// montant : c'est le troisième écran alimenté par l'API après le catalogue
/// et la fiche produit.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final user = ref.watch(currentUserProvider);
    final orders = ref.watch(ordersProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.orders)),
        body: EmptyState(
          icon: Icons.person_outline,
          title: strings.guest,
          subtitle: strings.unavailableForUser,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.orders),
        actions: [
          IconButton(
            tooltip: strings.retry,
            onPressed: () => ref.invalidate(ordersProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: orders.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: strings.errorGeneric,
                onRetry: () => ref.invalidate(ordersProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: strings.ordersEmpty,
                    subtitle: strings.unavailableForUser,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _OrderCard(order: items[index], strings: strings),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.strings});

  final Order order;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${strings.orderNumber} #${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  strings.itemsCount(order.totalQuantity),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.lines.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final line = order.lines[index];
                  return SizedBox(
                    width: 56,
                    child: RemoteImage(
                      url: line.thumbnail,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // `Wrap` : libellé et montant ne tiennent pas sur une ligne dans
            // une carte étroite ; l'en-tête peut passer à la ligne suivante.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 2,
              children: [
                Text(
                  '${strings.amountDue} : ',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                Text(
                  strings.price(order.amountDue),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
