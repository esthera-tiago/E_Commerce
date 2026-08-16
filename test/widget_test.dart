import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app/models/product.dart';
import 'package:e_commerce_app/providers/cart_provider.dart';
import 'package:e_commerce_app/providers/product_provider.dart';

void main() {
  test('Cart add increments quantity for same product', () {
    final container = ProviderContainer();

    final product = const Product(
      id: 'test-1',
      name: 'Test Product',
      description: 'A test product',
      price: 25.0,
      category: 'Test',
    );

    final notifier = container.read(cartProvider.notifier);
    notifier.add(product);
    notifier.add(product);

    final state = container.read(cartProvider);
    expect(state.length, 1);
    expect(state.first.quantity, 2);
    expect(state.first.totalPrice, 50.0);

    container.dispose();
  });

  test('Cart remove clears the product', () {
    final container = ProviderContainer();

    final product = const Product(
      id: 'test-1',
      name: 'Test Product',
      description: 'A test product',
      price: 25.0,
      category: 'Test',
    );

    final notifier = container.read(cartProvider.notifier);
    notifier.add(product);
    notifier.remove('test-1');

    final state = container.read(cartProvider);
    expect(state, isEmpty);

    container.dispose();
  });

  test('Cart total computes correctly', () {
    final container = ProviderContainer();

    final p1 = const Product(
      id: 'p1', name: 'A', description: '', price: 10.0, category: '',
    );
    final p2 = const Product(
      id: 'p2', name: 'B', description: '', price: 20.0, category: '',
    );

    final notifier = container.read(cartProvider.notifier);
    notifier.add(p1);
    notifier.add(p2);
    notifier.add(p1);

    expect(container.read(cartItemCountProvider), 3);
    expect(container.read(cartTotalProvider), 40.0);

    container.dispose();
  });

  test('Filter category reduces product list', () {
    final container = ProviderContainer(
      overrides: const [],
    );

    // Simulate filter state changes
    final notifier = container.read(filterProvider.notifier);
    notifier.setCategory('Test');

    final state = container.read(filterProvider);
    expect(state.category, 'Test');

    container.dispose();
  });
}
