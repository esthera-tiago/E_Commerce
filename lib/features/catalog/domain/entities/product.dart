import 'package:flutter/foundation.dart';

import 'product_review.dart';

/// Produit du catalogue, vu par le domaine.
///
/// Entité immuable et indépendante du format JSON de l'API.
@immutable
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    this.discountPercentage = 0,
    this.rating = 0,
    this.stock = 0,
    this.brand = '',
    this.sku = '',
    this.thumbnail = '',
    this.images = const [],
    this.tags = const [],
    this.availabilityStatus = '',
    this.shippingInformation = '',
    this.warrantyInformation = '',
    this.createdAt,
    this.reviews = const [],
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String brand;
  final String sku;
  final String thumbnail;
  final List<String> images;
  final List<String> tags;
  final String availabilityStatus;
  final String shippingInformation;
  final String warrantyInformation;
  final DateTime? createdAt;
  final List<ProductReview> reviews;

  /// Prix après application de la remise, arrondi au centime.
  double get discountedPrice =>
      double.parse((price * (1 - discountPercentage / 100)).toStringAsFixed(2));

  bool get isOnDiscount => discountPercentage > 0;
  bool get isInStock =>
      stock > 0 && availabilityStatus.toLowerCase() != 'out of stock';
  bool get isLowStock => stock > 0 && stock <= 10;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Product && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Product(id: $id, title: $title)';
}

/// Page de résultats renvoyée par une requête paginée du catalogue.
@immutable
class ProductPage {
  const ProductPage({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  const ProductPage.empty()
    : products = const [],
      total = 0,
      skip = 0,
      limit = 0;

  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  bool get hasMore => skip + products.length < total;

  int get nextSkip => skip + products.length;
}
