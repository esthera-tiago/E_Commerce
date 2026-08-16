import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/product.dart';

class ProductRepository {
  List<Product>? _cache;

  Future<List<Product>> loadProducts() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/products.json');
    final list = jsonDecode(raw) as List;
    _cache = list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<Product?> getProductById(String id) async {
    final products = await loadProducts();
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<List<String>> loadCategories() async {
    final products = await loadProducts();
    final cats = <String>{};
    for (final p in products) {
      cats.add(p.category);
    }
    return cats.toList()..sort();
  }
}
