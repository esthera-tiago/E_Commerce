import 'package:e_commerce_app/features/catalog/domain/entities/product.dart';
import 'package:flutter/foundation.dart';

/// Ligne d'une commande (« panier » dans le modèle de l'API).
@immutable
class OrderLine {
  const OrderLine({
    required this.productId,
    required this.title,
    required this.price,
    required this.quantity,
    required this.total,
    this.discountPercentage = 0,
    this.discountedTotal = 0,
    this.thumbnail = '',
  });

  final int productId;
  final String title;
  final double price;
  final int quantity;
  final double total;
  final double discountPercentage;
  final double discountedTotal;
  final String thumbnail;

  /// Le catalogue et les commandes partagent la même source : un produit déjà
  /// chargé permet d'afficher l'image via le pipeline d'images du catalogue.
  Product? toProduct() => thumbnail.isEmpty
      ? null
      : Product(
          id: productId,
          title: title,
          description: '',
          category: '',
          price: price,
          discountPercentage: discountPercentage,
          thumbnail: thumbnail,
          images: [thumbnail],
        );
}

/// Commande (panier) appartenant à un utilisateur.
@immutable
class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.lines,
    required this.total,
    required this.discountedTotal,
    required this.totalQuantity,
    this.discountPercentage = 0,
  });

  final int id;
  final int userId;
  final List<OrderLine> lines;
  final double total;
  final double discountedTotal;
  final int totalQuantity;
  final double discountPercentage;

  double get amountDue => discountedTotal > 0 ? discountedTotal : total;

  int get lineCount => lines.length;
}
