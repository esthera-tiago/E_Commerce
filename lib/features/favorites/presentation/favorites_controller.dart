import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/storage/json_cache_store.dart';
import '../../catalog/domain/entities/product.dart';

/// Favoris de l'utilisateur, stockés localement.
///
/// L'API ne propose pas de route de favoris : l'état est donc purement client,
/// mais persisté pour survivre à un redémarrage et au mode hors-ligne.
class FavoritesController extends StateNotifier<Set<int>> {
  FavoritesController(this._cache) : super(<int>{}) {
    _restore();
  }

  final JsonCacheStore _cache;

  static const _key = 'favorite_ids';

  Future<void> _restore() async {
    final raw = await _cache.read<List<dynamic>>(_key);
    if (raw == null) return;
    state = raw.whereType<int>().toSet();
  }

  bool contains(int productId) => state.contains(productId);

  void toggle(Product product) {
    final next = {...state};
    if (!next.remove(product.id)) next.add(product.id);
    state = next;
    _cache.write(_key, next.toList());
  }
}

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, Set<int>>(
      (ref) => FavoritesController(ref.watch(localStorageProvider).favorites),
    );

final isFavoriteProvider = Provider.family<bool, int>((ref, productId) {
  return ref.watch(favoritesControllerProvider).contains(productId);
});

/// Produits favoris, résolus via le cache du catalogue.
///
/// Résoudre l'identifiant contre le catalogue plutôt que de dupliquer les
/// fiches garantit des prix et images cohérents avec le reste de l'application.
final favoriteProductsProvider = FutureProvider<List<Product>>((ref) async {
  final ids = ref.watch(favoritesControllerProvider);
  if (ids.isEmpty) return const [];

  final repository = ref.watch(catalogRepositoryProvider);
  final results = await Future.wait(
    ids.map((id) async {
      try {
        return await repository.getProduct(id);
      } on ApiException {
        return null;
      }
    }),
  );
  return results.whereType<Product>().toList();
});
