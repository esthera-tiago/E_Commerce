import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/entities/order.dart';

/// Commandes du compte connecté, avec repli hors-ligne.
///
/// L'utilisateur est nécessaire : l'API expose `/carts/user/{userId}`. Sans
/// session, aucune commande n'est demandée plutôt que de renvoyer une erreur.
final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.watch(ordersRepositoryProvider).getOrders(user.id);
});
