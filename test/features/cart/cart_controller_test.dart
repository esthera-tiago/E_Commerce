import 'package:e_commerce_app/features/cart/presentation/cart_controller.dart';
import 'package:e_commerce_app/features/catalog/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_json_cache_store.dart';

/// Le panier est le seul état purement client de l'application : ces tests
/// verrouillent ses invariants (quantités, plafonds, totaux, persistance).
void main() {
  late FakeJsonCacheStore cache;
  late CartController controller;

  setUp(() {
    cache = FakeJsonCacheStore();
    controller = CartController(cache);
  });

  test('ajouter un produit crée une ligne à l’unité', () {
    controller.add(_product(1, price: 20));

    expect(controller.state.itemCount, 1);
    expect(controller.state.contains(1), isTrue);
    expect(controller.state.quantityOf(1), 1);
  });

  test('ajouter deux fois incrémente la ligne existante', () {
    controller.add(_product(1, price: 20));
    controller.add(_product(1, price: 20));

    expect(controller.state.items, hasLength(1));
    expect(controller.state.quantityOf(1), 2);
  });

  test('le sous-total utilise le prix remisé', () {
    controller.add(_product(1, price: 100, discount: 20));
    controller.add(_product(1, price: 100, discount: 20));
    controller.add(_product(2, price: 50));

    // 2 x 80 + 1 x 50
    expect(controller.state.subtotal, closeTo(210, 0.001));
    expect(controller.state.itemCount, 3);
  });

  test('décrémenter sous 1 retire la ligne', () {
    controller.add(_product(1, price: 20));
    controller.decrement(_product(1, price: 20));

    expect(controller.state.isEmpty, isTrue);
  });

  test('décrémenter un produit absent ne fait rien', () {
    controller.add(_product(1, price: 20));

    controller.decrement(_product(99, price: 20));

    expect(controller.state.itemCount, 1);
  });

  test('la quantité est plafonnée par ligne', () {
    for (var i = 0; i < 25; i++) {
      controller.add(_product(1, price: 20));
    }

    expect(controller.state.quantityOf(1), 20);
  });

  test('remove et clear vident le panier', () {
    controller.add(_product(1, price: 20));
    controller.add(_product(2, price: 30));
    controller.remove(_product(1, price: 20));

    expect(controller.state.items, hasLength(1));

    controller.clear();

    expect(controller.state.isEmpty, isTrue);
  });

  test('checkout renvoie le contenu puis vide le panier', () {
    controller.add(_product(1, price: 20));
    controller.add(_product(1, price: 20));

    final snapshot = controller.checkout();

    expect(snapshot, hasLength(1));
    expect(snapshot.single.quantity, 2);
    expect(controller.state.isEmpty, isTrue);
  });

  test('le panier est persisté puis restauré', () async {
    controller.add(_product(1, price: 20, discount: 10));
    controller.add(_product(1, price: 20, discount: 10));
    await Future<void>.delayed(Duration.zero);

    // Nouvelle instance : même cache, état reconstruit depuis Hive.
    final restored = CartController(cache);
    await Future<void>.delayed(Duration.zero);

    expect(restored.state.quantityOf(1), 2);
    expect(restored.state.subtotal, closeTo(36, 0.001));
  });

  test('une entrée de cache corrompue est ignorée', () async {
    await cache.write('cart_items', [
      {'quantity': 2, 'product': 'pas-une-carte'},
      {
        'quantity': 1,
        'product': <String, dynamic>{'id': 5, 'title': 'Produit'},
      },
    ]);

    final restored = CartController(cache);
    await Future<void>.delayed(Duration.zero);

    expect(restored.state.items, hasLength(1));
    expect(restored.state.items.single.product.id, 5);
  });
}

Product _product(int id, {required double price, double discount = 0}) =>
    Product(
      id: id,
      title: 'Produit $id',
      description: '',
      category: '',
      price: price,
      discountPercentage: discount,
      stock: 10,
    );
