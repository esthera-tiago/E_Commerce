import '../../domain/entities/order.dart';

/// DTO d'une ligne de commande.
class OrderLineDto {
  const OrderLineDto({
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

  factory OrderLineDto.fromJson(Map<String, dynamic> json) {
    return OrderLineDto(
      productId: _int(json['id']),
      title: _str(json['title']) ?? '',
      price: _double(json['price']) ?? 0,
      quantity: _int(json['quantity']),
      total: _double(json['total']) ?? 0,
      discountPercentage: _double(json['discountPercentage']) ?? 0,
      discountedTotal: _double(json['discountedTotal']) ?? 0,
      thumbnail: _str(json['thumbnail']) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': productId,
    'title': title,
    'price': price,
    'quantity': quantity,
    'total': total,
    'discountPercentage': discountPercentage,
    'discountedTotal': discountedTotal,
    'thumbnail': thumbnail,
  };

  OrderLine toEntity() => OrderLine(
    productId: productId,
    title: title,
    price: price,
    quantity: quantity,
    total: total,
    discountPercentage: discountPercentage,
    discountedTotal: discountedTotal,
    thumbnail: thumbnail,
  );
}

/// DTO d'une commande.
class OrderDto {
  const OrderDto({
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
  final List<OrderLineDto> lines;
  final double total;
  final double discountedTotal;
  final int totalQuantity;
  final double discountPercentage;

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    final products = json['products'];
    return OrderDto(
      id: _int(json['id']),
      userId: _int(json['userId']),
      lines: products is List
          ? products
                .whereType<Map<String, dynamic>>()
                .map(OrderLineDto.fromJson)
                .toList()
          : const [],
      total: _double(json['total']) ?? 0,
      discountedTotal: _double(json['discountedTotal']) ?? 0,
      totalQuantity: _int(json['totalQuantity']),
      discountPercentage: _double(json['discountPercentage']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'products': lines.map((l) => l.toJson()).toList(),
    'total': total,
    'discountedTotal': discountedTotal,
    'totalQuantity': totalQuantity,
    'discountPercentage': discountPercentage,
  };

  Order toEntity() => Order(
    id: id,
    userId: userId,
    lines: lines.map((l) => l.toEntity()).toList(),
    total: total,
    discountedTotal: discountedTotal,
    totalQuantity: totalQuantity,
    discountPercentage: discountPercentage,
  );
}

/// DTO de la collection de commandes.
///
/// L'API renvoie `{ "carts": [...], "total": n, "skip": n, "limit": n }`.
class OrderListDto {
  const OrderListDto({required this.orders});

  final List<OrderDto> orders;

  factory OrderListDto.fromJson(Map<String, dynamic> json) {
    final carts = json['carts'];
    return OrderListDto(
      orders: (carts is List ? carts : const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderDto.fromJson)
          .toList(),
    );
  }

  List<Order> toEntities() => orders.map((o) => o.toEntity()).toList();
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? _str(Object? value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}
