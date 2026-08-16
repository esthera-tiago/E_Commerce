enum SortOption { priceAsc, priceDesc, rating, newest }

class FilterState {
  const FilterState({
    this.searchQuery = '',
    this.category = '',
    this.sortOption = SortOption.newest,
    this.minPrice = 0.0,
    this.maxPrice = 10000.0,
  });

  final String searchQuery;
  final String category;
  final SortOption sortOption;
  final double minPrice;
  final double maxPrice;

  FilterState copyWith({
    String? searchQuery,
    String? category,
    SortOption? sortOption,
    double? minPrice,
    double? maxPrice,
  }) {
    return FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      sortOption: sortOption ?? this.sortOption,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}
