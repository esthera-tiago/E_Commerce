import '../../../../core/storage/json_cache_store.dart';
import '../models/product_dto.dart';

/// Persistance locale du catalogue dans Hive.
///
/// Le cache est indexé par « filtre » afin qu'une recherche hors-ligne rende
/// encore un résultat pertinent plutôt que la première page du catalogue.
class CatalogLocalDataSource {
  CatalogLocalDataSource(this._cache);

  final JsonCacheStore _cache;

  static const _pagePrefix = 'products_page';
  static const _productPrefix = 'product_detail';
  static const _categoriesKey = 'categories';

  /// Clé déterministe pour une page donnée.
  ///
  /// Les paramètres inutiles sont omis afin que « liste simple » et
  /// « liste sans catégorie » partagent la même entrée de cache.
  String _pageKey({
    required int skip,
    int limit = 20,
    String? query,
    String? category,
  }) {
    final q = query?.trim().toLowerCase() ?? '';
    final c = category?.trim() ?? '';
    return '$_pagePrefix|skip=$skip|limit=$limit'
        '${q.isEmpty ? '' : '|q=$q'}'
        '${c.isEmpty ? '' : '|c=$c'}';
  }

  Future<void> cachePage({
    required ProductPageDto page,
    required int limit,
    String? query,
    String? category,
  }) {
    return _cache.write(
      _pageKey(skip: page.skip, limit: limit, query: query, category: category),
      {
        'products': page.products.map((p) => p.toJson()).toList(),
        'total': page.total,
        'skip': page.skip,
        'limit': page.limit,
      },
    );
  }

  Future<ProductPageDto?> readPage({
    required int skip,
    int limit = 20,
    String? query,
    String? category,
  }) async {
    final raw = await _cache.read<Map<String, dynamic>>(
      _pageKey(skip: skip, limit: limit, query: query, category: category),
    );
    if (raw == null) return null;
    try {
      final list = raw['products'];
      return ProductPageDto(
        products: (list is List ? list : const [])
            .whereType<Map<String, dynamic>>()
            .map(ProductDto.fromJson)
            .toList(),
        total: _toInt(raw['total']),
        skip: _toInt(raw['skip']),
        limit: _toInt(raw['limit']),
      );
    } on Object {
      return null;
    }
  }

  Future<void> cacheProduct(ProductDto product) =>
      _cache.write('$_productPrefix${product.id}', product.toJson());

  Future<ProductDto?> readProduct(int id) async {
    final raw = await _cache.read<Map<String, dynamic>>('$_productPrefix$id');
    if (raw == null) return null;
    try {
      return ProductDto.fromJson(raw);
    } on Object {
      return null;
    }
  }

  Future<void> cacheCategories(List<CategoryDto> categories) =>
      _cache.write(_categoriesKey, categories.map((c) => c.toJson()).toList());

  Future<List<CategoryDto>?> readCategories() async {
    final raw = await _cache.read<List<dynamic>>(_categoriesKey);
    if (raw == null) return null;
    try {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(CategoryDto.fromJson)
          .toList();
    } on Object {
      return null;
    }
  }

  /// Âge de la page en cache, pour informer l'utilisateur de l'ancienneté des
  /// données hors-ligne. `null` si aucune copie n'existe.
  Future<Duration?> pageAge({required int skip, int limit = 20}) =>
      _cache.ageOf(_pageKey(skip: skip, limit: limit));

  Future<void> clear() => _cache.clear();

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
