import '../../domain/entities/order.dart';

/// Contrat d'accès aux commandes de l'utilisateur authentifié.
abstract interface class OrdersRepository {
  /// Commandes de l'utilisateur. Hors-ligne, la dernière copie en cache est
  /// retournée si elle existe.
  Future<List<Order>> getOrders(int userId);

  /// Purge le cache des commandes.
  Future<void> clearCache();
}
