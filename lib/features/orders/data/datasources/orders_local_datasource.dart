import '../../../../core/storage/json_cache_store.dart';
import '../models/order_dto.dart';

/// Persistance locale des commandes dans Hive.
class OrdersLocalDataSource {
  OrdersLocalDataSource(this._cache);

  final JsonCacheStore _cache;

  /// La clé inclut l'identifiant utilisateur : deux comptes sur le même
  /// appareil ne doivent jamais voir les commandes de l'autre.
  String _key(int userId) => 'orders_user_$userId';

  Future<void> cacheOrders(int userId, List<OrderDto> orders) =>
      _cache.write(_key(userId), orders.map((o) => o.toJson()).toList());

  Future<List<OrderDto>?> readOrders(int userId) async {
    final raw = await _cache.read<List<dynamic>>(_key(userId));
    if (raw == null) return null;
    try {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(OrderDto.fromJson)
          .toList();
    } on Object {
      return null;
    }
  }

  Future<Duration?> cacheAge(int userId) => _cache.ageOf(_key(userId));

  Future<void> clear() => _cache.clear();
}
