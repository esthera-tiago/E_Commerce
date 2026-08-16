import 'package:flutter/foundation.dart';

import 'product.dart';

@immutable
class CartItem {
  const CartItem({
    required this.product,
    this.quantity = 1,
  });

  final Product product;
  final int quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }

  double get totalPrice => product.price * quantity;
}
