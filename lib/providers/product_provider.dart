import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/product_repository.dart';
import '../models/filter_state.dart';
import '../models/product.dart';

/// Singleton repository instance.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

/// All products loaded from the local JSON asset.
final productListProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.loadProducts();
});

/// Available category strings.
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.loadCategories();
});

/// Current filter state (category, sort, search, price range).
final filterProvider =
    StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setCategory(String c) => state = state.copyWith(category: c);
  void setSort(SortOption s) => state = state.copyWith(sortOption: s);
  void setPriceRange(double min, double max) =>
      state = state.copyWith(minPrice: min, maxPrice: max);
  void reset() => state = const FilterState();
}

/// Derived provider: products filtered + sorted by the current FilterState.
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final productsAsync = ref.watch(productListProvider);
  final filter = ref.watch(filterProvider);

  return productsAsync.when(
    data: (products) {
      var result = List<Product>.from(products);

      // Search filter
      if (filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        result = result
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q))
            .toList();
      }

      // Category filter
      if (filter.category.isNotEmpty) {
        result = result.where((p) => p.category == filter.category).toList();
      }

      // Price filter
      result = result
          .where((p) =>
              p.price >= filter.minPrice && p.price <= filter.maxPrice)
          .toList();

      // Sort
      switch (filter.sortOption) {
        case SortOption.priceAsc:
          result.sort((a, b) => a.price.compareTo(b.price));
        case SortOption.priceDesc:
          result.sort((a, b) => b.price.compareTo(a.price));
        case SortOption.rating:
          result.sort((a, b) => b.rating.compareTo(a.rating));
        case SortOption.newest:
          break; // keep original order
      }

      return result;
    },
    loading: () => [],
    error: (_, _) => [],
  );
});
