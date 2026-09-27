import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/storage/json_cache_store.dart';
import '../../catalog/domain/entities/product.dart';

/// Ligne du panier local.
@immutable
class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get lineTotal => product.discountedPrice * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}

@immutable
class CartState {
  const CartState({this.items = const []});

  final List<CartItem> items;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.lineTotal);

  bool get isEmpty => items.isEmpty;

  bool contains(int productId) =>
      items.any((item) => item.product.id == productId);

  int quantityOf(int productId) {
    for (final item in items) {
      if (item.product.id == productId) return item.quantity;
    }
    return 0;
  }
}

/// Panier local, persisté dans Hive.
///
/// Le catalogue vient de l'API mais le panier est un état purement client :
/// l'API de démonstration n'expose pas de création de commande. Le stock de
/// chaque ligne est donc mémorisé pour rendre l'écran utilisable hors-ligne.
class CartController extends StateNotifier<CartState> {
  CartController(this._cache) : super(const CartState()) {
    _restore();
  }

  final JsonCacheStore _cache;

  static const _key = 'cart_items';
  static const _maxPerLine = 20;

  Future<void> _restore() async {
    final raw = await _cache.read<List<dynamic>>(_key);
    if (raw == null) return;
    final items = <CartItem>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final quantity = entry['quantity'];
      // Une entrée dont la charge utile produit est illisible est écartée :
      // la conserver produirait une ligne fantôme (identifiant 0, prix nul)
      // impossible à retirer proprement depuis l'interface.
      if (quantity is! int || entry['product'] is! Map<String, dynamic>) {
        continue;
      }
      items.add(
        CartItem(
          product: ProductDtoCache.fromJson(entry['product']),
          quantity: quantity.clamp(1, _maxPerLine),
        ),
      );
    }
    if (items.isNotEmpty) state = CartState(items: items);
  }

  /// Ajoute une unité du produit, ou incrémente la ligne existante.
  void add(Product product) {
    final existing = state.items.where((i) => i.product.id == product.id);
    final items = [...state.items];
    if (existing.isEmpty) {
      items.add(CartItem(product: product, quantity: 1));
    } else {
      final index = items.indexWhere((i) => i.product.id == product.id);
      final current = items[index].quantity;
      items[index] = items[index].copyWith(
        quantity: current >= _maxPerLine ? _maxPerLine : current + 1,
      );
    }
    _commit(items);
  }

  void decrement(Product product) {
    final items = [...state.items];
    final index = items.indexWhere((i) => i.product.id == product.id);
    if (index == -1) return;
    final quantity = items[index].quantity - 1;
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      items[index] = items[index].copyWith(quantity: quantity);
    }
    _commit(items);
  }

  void remove(Product product) {
    _commit(state.items.where((i) => i.product.id != product.id).toList());
  }

  void clear() => _commit(const []);

  /// Vide le panier et renvoie son contenu : utilisé par la confirmation de
  /// commande, qui a besoin du récapitulatif affiché avant le vidage.
  List<CartItem> checkout() {
    final snapshot = state.items;
    clear();
    return snapshot;
  }

  void _commit(List<CartItem> items) {
    state = CartState(items: items);
    _cache.write(
      _key,
      items
          .map(
            (item) => {
              'quantity': item.quantity,
              'product': ProductDtoCache.toJson(item.product),
            },
          )
          .toList(),
    );
  }
}

/// Sérialisation minimale d'un produit pour le cache du panier.
///
/// On ne réutilise volontairement pas le DTO de l'API : le panier n'a besoin
/// que de ce qu'il affiche, et ce format survit à une évolution du catalogue.
abstract final class ProductDtoCache {
  static Map<String, dynamic> toJson(Product product) => {
    'id': product.id,
    'title': product.title,
    'description': product.description,
    'category': product.category,
    'price': product.price,
    'discountPercentage': product.discountPercentage,
    'rating': product.rating,
    'stock': product.stock,
    'brand': product.brand,
    'sku': product.sku,
    'thumbnail': product.thumbnail,
    'images': product.images,
    'tags': product.tags,
  };

  static Product fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return const Product(
        id: 0,
        title: '',
        description: '',
        category: '',
        price: 0,
      );
    }
    return Product(
      id: (raw['id'] as num?)?.toInt() ?? 0,
      title: (raw['title'] as String?) ?? '',
      description: (raw['description'] as String?) ?? '',
      category: (raw['category'] as String?) ?? '',
      price: (raw['price'] as num?)?.toDouble() ?? 0,
      discountPercentage: (raw['discountPercentage'] as num?)?.toDouble() ?? 0,
      rating: (raw['rating'] as num?)?.toDouble() ?? 0,
      stock: (raw['stock'] as num?)?.toInt() ?? 0,
      brand: (raw['brand'] as String?) ?? '',
      sku: (raw['sku'] as String?) ?? '',
      thumbnail: (raw['thumbnail'] as String?) ?? '',
      images: (raw['images'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      tags: (raw['tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

final cartControllerProvider = StateNotifierProvider<CartController, CartState>(
  (ref) => CartController(ref.watch(localStorageProvider).cart),
);

/// Badge du panier affiché dans la barre de navigation.
final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartControllerProvider).itemCount,
);
