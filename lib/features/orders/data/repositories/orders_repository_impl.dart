import 'dart:async';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_local_datasource.dart';
import '../datasources/orders_remote_datasource.dart';

/// Repository des commandes — même stratégie offline-first que le catalogue :
/// réseau prioritaire, repli sur le cache en cas de panne réseau uniquement.
class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl({
    required OrdersRemoteDataSource remote,
    required OrdersLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  final OrdersRemoteDataSource _remote;
  final OrdersLocalDataSource _local;

  @override
  Future<List<Order>> getOrders(int userId) async {
    try {
      final page = await _remote.fetchOrders(userId);
      unawaited(_local.cacheOrders(userId, page.orders));
      return page.toEntities();
    } on ApiException catch (error) {
      if (error.failure is NetworkFailure) {
        final cached = await _local.readOrders(userId);
        // Une liste vide en cache reste une réponse valide : l'utilisateur a
        // simplement aucune commande.
        if (cached != null) return cached.map((o) => o.toEntity()).toList();
      }
      rethrow;
    }
  }

  @override
  Future<void> clearCache() => _local.clear();
}
