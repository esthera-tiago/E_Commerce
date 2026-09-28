import 'package:e_commerce_app/core/error/error_mapper.dart';
import 'package:e_commerce_app/core/error/failure.dart';
import 'package:e_commerce_app/features/orders/data/datasources/orders_local_datasource.dart';
import 'package:e_commerce_app/features/orders/data/datasources/orders_remote_datasource.dart';
import 'package:e_commerce_app/features/orders/data/models/order_dto.dart';
import 'package:e_commerce_app/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fake_json_cache_store.dart';

class _MockRemote extends Mock implements OrdersRemoteDataSource {}

/// Vérifie que les commandes suivent la même stratégie offline-first que le
/// catalogue, et surtout que le cache est cloisonné par utilisateur.
void main() {
  late _MockRemote remote;
  late FakeJsonCacheStore cache;
  late OrdersRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const OrderDto(
        id: 1,
        userId: 7,
        lines: [],
        total: 0,
        discountedTotal: 0,
        totalQuantity: 0,
      ),
    );
  });

  setUp(() {
    remote = _MockRemote();
    cache = FakeJsonCacheStore();
    repository = OrdersRepositoryImpl(
      remote: remote,
      local: OrdersLocalDataSource(cache),
    );
  });

  test('retourne les commandes de l’API et les met en cache', () async {
    when(
      () => remote.fetchOrders(7),
    ).thenAnswer((_) async => OrderListDto(orders: [_orderDto()]));

    final orders = await repository.getOrders(7);

    expect(orders, hasLength(1));
    expect(orders.single.totalQuantity, 2);
    expect(orders.single.lines.single.productId, 11);
    await Future<void>.delayed(Duration.zero);
    expect(await cache.has('orders_user_7'), isTrue);
  });

  test('retombe sur le cache lors d’une panne réseau', () async {
    when(
      () => remote.fetchOrders(7),
    ).thenThrow(const ApiException(NetworkFailure()));
    await cache.write('orders_user_7', [_orderDto().toJson()]);

    final orders = await repository.getOrders(7);

    expect(orders.single.id, 42);
  });

  test('ne montre pas les commandes d’un autre utilisateur', () async {
    when(
      () => remote.fetchOrders(7),
    ).thenThrow(const ApiException(NetworkFailure()));
    // Cache alimenté par la session d'un autre compte sur le même appareil.
    await cache.write('orders_user_9', [_orderDto().toJson()]);

    await expectLater(repository.getOrders(7), throwsA(isA<ApiException>()));
  });

  test('propage une erreur serveur sans lire le cache', () async {
    when(
      () => remote.fetchOrders(7),
    ).thenThrow(const ApiException(ServerFailure(statusCode: 500)));
    await cache.write('orders_user_7', [_orderDto().toJson()]);

    await expectLater(
      repository.getOrders(7),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          isA<ServerFailure>(),
        ),
      ),
    );
  });

  test('une liste vide en cache est une réponse valide', () async {
    when(
      () => remote.fetchOrders(7),
    ).thenThrow(const ApiException(NetworkFailure()));
    await cache.write('orders_user_7', <dynamic>[]);

    expect(await repository.getOrders(7), isEmpty);
  });

  test('clearCache purge les commandes', () async {
    when(
      () => remote.fetchOrders(7),
    ).thenAnswer((_) async => OrderListDto(orders: [_orderDto()]));
    await repository.getOrders(7);
    await Future<void>.delayed(Duration.zero);

    await repository.clearCache();

    expect(await cache.has('orders_user_7'), isFalse);
  });
}

OrderDto _orderDto() => const OrderDto(
  id: 42,
  userId: 7,
  lines: [
    OrderLineDto(
      productId: 11,
      title: 'Test product',
      price: 20,
      quantity: 2,
      total: 40,
    ),
  ],
  total: 40,
  discountedTotal: 36,
  totalQuantity: 2,
);
