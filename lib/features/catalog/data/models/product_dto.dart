import '../../domain/entities/product.dart';
import '../../domain/entities/product_review.dart';

/// DTO d'un avis client.
class ReviewDto {
  const ReviewDto({
    required this.reviewerName,
    required this.rating,
    required this.comment,
    this.date,
  });

  final String reviewerName;
  final double rating;
  final String comment;
  final DateTime? date;

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    return ReviewDto(
      reviewerName: _str(json['reviewerName']) ?? 'Client',
      rating: _num(json['rating'])?.toDouble() ?? 0,
      comment: _str(json['comment']) ?? '',
      date: DateTime.tryParse(_str(json['date']) ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'reviewerName': reviewerName,
    'rating': rating,
    'comment': comment,
    'date': date?.toIso8601String(),
  };

  ProductReview toEntity() => ProductReview(
    reviewerName: reviewerName,
    rating: rating,
    comment: comment,
    date: date,
  );
}

/// DTO d'un produit renvoyé par l'API.
class ProductDto {
  const ProductDto({
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
  final List<ReviewDto> reviews;

  /// Conversion défensive : l'API peut renvoyer `null` ou un type inattendu
  /// sur n'importe quel champ. Sans ces garde-fous, un champ manquant ferait
  /// planter toute la liste du catalogue.
  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      id: _num(json['id'])?.toInt() ?? 0,
      title: _str(json['title']) ?? '',
      description: _str(json['description']) ?? '',
      category: _str(json['category']) ?? '',
      price: _num(json['price'])?.toDouble() ?? 0,
      discountPercentage: _num(json['discountPercentage'])?.toDouble() ?? 0,
      rating: _num(json['rating'])?.toDouble() ?? 0,
      stock: _num(json['stock'])?.toInt() ?? 0,
      brand: _str(json['brand']) ?? '',
      sku: _str(json['sku']) ?? '',
      thumbnail: _str(json['thumbnail']) ?? '',
      images: _strList(json['images']),
      tags: _strList(json['tags']),
      availabilityStatus: _str(json['availabilityStatus']) ?? '',
      shippingInformation: _str(json['shippingInformation']) ?? '',
      warrantyInformation: _str(json['warrantyInformation']) ?? '',
      createdAt: _parseDate(
        json['meta'] is Map<String, dynamic>
            ? (json['meta'] as Map<String, dynamic>)['createdAt']
            : null,
      ),
      reviews: _reviewList(json['reviews']),
    );
  }

  /// L'API renvoie aussi un objet unique enveloppé dans `{"product": {...}}`.
  factory ProductDto.fromEnvelope(Map<String, dynamic> json) {
    final nested = json['product'];
    return ProductDto.fromJson(nested is Map<String, dynamic> ? nested : json);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'price': price,
    'discountPercentage': discountPercentage,
    'rating': rating,
    'stock': stock,
    'brand': brand,
    'sku': sku,
    'thumbnail': thumbnail,
    'images': images,
    'tags': tags,
    'availabilityStatus': availabilityStatus,
    'shippingInformation': shippingInformation,
    'warrantyInformation': warrantyInformation,
    'meta': {'createdAt': createdAt?.toIso8601String()},
    'reviews': reviews.map((r) => r.toJson()).toList(),
  };

  Product toEntity() => Product(
    id: id,
    title: title,
    description: description,
    category: category,
    price: price,
    discountPercentage: discountPercentage,
    rating: rating,
    stock: stock,
    brand: brand,
    sku: sku,
    thumbnail: thumbnail,
    images: images.isNotEmpty
        ? images
        : (thumbnail.isEmpty ? const [] : [thumbnail]),
    tags: tags,
    availabilityStatus: availabilityStatus,
    shippingInformation: shippingInformation,
    warrantyInformation: warrantyInformation,
    createdAt: createdAt,
    reviews: reviews.map((r) => r.toEntity()).toList(),
  );
}

/// DTO d'une page paginée de produits.
class ProductPageDto {
  const ProductPageDto({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<ProductDto> products;
  final int total;
  final int skip;
  final int limit;

  /// Forme exacte du payload renvoyé par l'API pour une page de produits :
  /// `{ "products": [...], "total": 194, "skip": 0, "limit": 20 }`.
  factory ProductPageDto.fromJson(Map<String, dynamic> json) {
    final list = json['products'];
    return ProductPageDto(
      products: list is List
          ? list
                .whereType<Map<String, dynamic>>()
                .map(ProductDto.fromJson)
                .toList()
          : const [],
      total: _num(json['total'])?.toInt() ?? 0,
      skip: _num(json['skip'])?.toInt() ?? 0,
      limit: _num(json['limit'])?.toInt() ?? 0,
    );
  }

  ProductPage toEntity() => ProductPage(
    products: products.map((p) => p.toEntity()).toList(),
    total: total,
    skip: skip,
    limit: limit,
  );
}

/// DTO d'une catégorie.
class CategoryDto {
  const CategoryDto({required this.slug, required this.name});

  final String slug;
  final String name;

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      slug: _str(json['slug']) ?? '',
      name: _str(json['name']) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'slug': slug, 'name': name};

  ProductCategory toEntity() => ProductCategory(slug: slug, name: name);
}

String? _str(Object? value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}

double? _num(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<String> _strList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((e) => e?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
}

List<ReviewDto> _reviewList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(ReviewDto.fromJson)
      .toList();
}

DateTime? _parseDate(Object? value) => DateTime.tryParse(_str(value) ?? '');
