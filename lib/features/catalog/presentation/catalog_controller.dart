import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/di/providers.dart';
import '../../../core/error/error_mapper.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/entities/product.dart';
import '../domain/repositories/catalog_repository.dart';

/// Options de tri du catalogue.
enum ProductSort { relevance, priceAscending, priceDescending, rating }

/// État du catalogue : pagination, filtres et mode de provenance des données.
@immutable
class CatalogState {
  const CatalogState({
    this.products = const [],
    this.query = '',
    this.category,
    this.sort = ProductSort.relevance,
    this.skip = 0,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.isOffline = false,
  });

  final List<Product> products;
  final String query;
  final String? category;
  final ProductSort sort;
  final int skip;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  /// `true` si les données affichées proviennent du cache (mode hors-ligne).
  final bool isOffline;

  bool get hasMore => skip < total;

  /// Vrai seulement lors du tout premier chargement, pour ne pas faire
  /// clignoter la liste à chaque « charger plus ».
  bool get isInitialLoad => isLoading && products.isEmpty;

  CatalogState copyWith({
    List<Product>? products,
    String? query,
    Object? category = _unset,
    ProductSort? sort,
    int? skip,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error = _unset,
    bool? isOffline,
  }) {
    return CatalogState(
      products: products ?? this.products,
      query: query ?? this.query,
      category: category == _unset ? this.category : category as String?,
      sort: sort ?? this.sort,
      skip: skip ?? this.skip,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error == _unset ? this.error : error as String?,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  static const _unset = Object();

  /// Le tri est appliqué côté client : l'API ne propose pas de paramètre
  /// `sort` sur `/products`, et 194 produits tiennent largement en mémoire.
  List<Product> get visibleProducts => switch (sort) {
    ProductSort.relevance => products,
    ProductSort.priceAscending => [
      ...products,
    ]..sort((a, b) => a.price.compareTo(b.price)),
    ProductSort.priceDescending => [
      ...products,
    ]..sort((a, b) => b.price.compareTo(a.price)),
    ProductSort.rating => [
      ...products,
    ]..sort((a, b) => b.rating.compareTo(a.rating)),
  };
}

/// Pilote la liste paginée du catalogue.
///
/// Le tri est appliqué après réception de la page, jamais en amont : cela
/// garantit que la pagination reste cohérente avec les indexes de l'API.
class CatalogController extends StateNotifier<CatalogState> {
  CatalogController(this._ref) : super(const CatalogState());

  final Ref _ref;

  CatalogRepository get _repository => _ref.read(catalogRepositoryProvider);

  /// Charge la première page. Utilisé au premier affichage et par le
  /// rafraîchissement manuel.
  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = await _repository.getProducts(
        limit: AppConfig.catalogPageSize,
        query: _nullableQuery(state.query),
        category: state.category,
      );
      state = state.copyWith(
        products: page.products,
        skip: page.nextSkip,
        total: page.total,
        isLoading: false,
        isOffline: _ref.read(isOfflineProvider),
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: _ref.read(appStringsProvider).failure(error.failure),
      );
    }
  }

  /// Pagination incrémentale déclenchée par le défilement.
  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final page = await _repository.getProducts(
        limit: AppConfig.catalogPageSize,
        skip: state.skip,
        query: _nullableQuery(state.query),
        category: state.category,
      );
      state = state.copyWith(
        products: [...state.products, ...page.products],
        skip: page.nextSkip,
        total: page.total,
        isLoadingMore: false,
      );
    } on ApiException catch (error) {
      // Un échec sur « charger plus » conserve les produits déjà affichés.
      state = state.copyWith(
        isLoadingMore: false,
        error: _ref.read(appStringsProvider).failure(error.failure),
      );
    }
  }

  Future<void> search(String value) async {
    final query = value.trim();
    if (query == state.query) return;
    state = state.copyWith(query: query, products: const [], skip: 0, total: 0);
    await load();
  }

  Future<void> selectCategory(String? category) async {
    if (category == state.category) return;
    state = state.copyWith(
      category: category,
      products: const [],
      skip: 0,
      total: 0,
    );
    await load();
  }

  void setSort(ProductSort sort) => state = state.copyWith(sort: sort);

  void clearError() => state = state.copyWith(error: null);

  static String? _nullableQuery(String query) => query.isEmpty ? null : query;
}

final catalogControllerProvider =
    StateNotifierProvider<CatalogController, CatalogState>(
      CatalogController.new,
    );

/// Catégories disponibles, mises en cache pour un usage hors-ligne.
final categoriesProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  try {
    final categories = await ref
        .watch(catalogRepositoryProvider)
        .getCategories();
    return categories.map((c) => c.name).toList()..sort();
  } on ApiException {
    return const [];
  }
});

/// Détail d'un produit. `autoDispose` évite de conserver 194 fiches en mémoire
/// au fur et à mesure de la navigation.
final productDetailProvider = FutureProvider.autoDispose.family<Product, int>((
  ref,
  id,
) async {
  return ref.watch(catalogRepositoryProvider).getProduct(id);
});
