import 'package:flutter/foundation.dart';

/// Avis client associé à un produit, renvoyé par l'API dans le tableau
/// `reviews` de chaque produit.
@immutable
class ProductReview {
  const ProductReview({
    required this.reviewerName,
    required this.rating,
    required this.comment,
    this.date,
  });

  final String reviewerName;
  final double rating;
  final String comment;
  final DateTime? date;

  String get reviewerInitials {
    final parts = reviewerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

/// Catégorie de produit, telle que retournée par `GET /products/categories`.
@immutable
class ProductCategory {
  const ProductCategory({required this.slug, required this.name});

  final String slug;
  final String name;

  /// Libellé lisible à partir du slug kebab-case renvoyé par l'API
  /// (« home-decoration » -> « Home decoration »).
  String get displayName => name.isNotEmpty ? name : _humanize(slug);

  static String _humanize(String slug) => slug
      .split('-')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
