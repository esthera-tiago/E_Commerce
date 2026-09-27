import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/common.dart';
import '../catalog_controller.dart';
import '../widgets/product_card.dart';

/// Écran principal : catalogue paginé alimenté par l'API.
///
/// Deux mécanismes de rafraîchissement cohabitent :
/// - le défilement déclenche `loadMore()` pour la pagination serveur ;
/// - un `RefreshIndicator` recharge la première page, ce qui permet de
///   rattraper un état hors-ligne dès que la connexion revient.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.onOpenProduct});

  final void Function(int productId) onOpenProduct;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Le catalogue est chargé une seule fois : l'écran est `autoDispose` côté
    // routeur, Riverpod conserve l'état pendant le navigation retour.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Déclenche la page suivante à 80 % de la hauteur visible : le
    // préchargement masque la latence sans charger toute la liste.
    if (position.pixels >= position.maxScrollExtent * 0.8) {
      ref.read(catalogControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() =>
      ref.read(catalogControllerProvider.notifier).load();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final state = ref.watch(catalogControllerProvider);
    final categories = ref.watch(categoriesProvider);
    final scheme = Theme.of(context).colorScheme;
    final columns = MediaQuery.sizeOf(context).width > 700 ? 4 : 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        actions: [
          PopupMenuButton<ProductSort>(
            icon: const Icon(Icons.sort),
            tooltip: strings.sortBy,
            initialValue: state.sort,
            onSelected: ref.read(catalogControllerProvider.notifier).setSort,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: ProductSort.relevance,
                child: Text(strings.sortRelevance),
              ),
              PopupMenuItem(
                value: ProductSort.priceAscending,
                child: Text(strings.sortPriceAsc),
              ),
              PopupMenuItem(
                value: ProductSort.priceDescending,
                child: Text(strings.sortPriceDesc),
              ),
              PopupMenuItem(
                value: ProductSort.rating,
                child: Text(strings.sortRating),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => ref
                      .read(catalogControllerProvider.notifier)
                      .search(value),
                  decoration: InputDecoration(
                    hintText: strings.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(catalogControllerProvider.notifier)
                                  .search('');
                            },
                          ),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              SizedBox(
                height: 44,
                child: categories.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (names) => ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(strings.allCategories),
                          selected: state.category == null,
                          onSelected: (_) => ref
                              .read(catalogControllerProvider.notifier)
                              .selectCategory(null),
                        ),
                      ),
                      for (final name in names)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(name),
                            selected: state.category == name,
                            onSelected: (selected) => ref
                                .read(catalogControllerProvider.notifier)
                                .selectCategory(selected ? name : null),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          if (state.isOffline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  strings.resultsCount(state.products.length),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Expanded(child: _buildBody(strings, columns)),
        ],
      ),
    );
  }

  Widget _buildBody(AppStrings strings, int columns) {
    final state = ref.watch(catalogControllerProvider);

    if (state.isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.products.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: ref.read(catalogControllerProvider.notifier).load,
      );
    }
    if (state.products.isEmpty) {
      return EmptyState(icon: Icons.search_off, title: strings.noResults);
    }

    final products = state.visibleProducts;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: GridView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          // Les tuiles doivent accueillir le bloc texte sous l'image : à 0.68
          // la partie texte était trop courte et débordait en français, dont
          // les libellés et montants formatés sont plus longs.
          childAspectRatio: 0.6,
        ),
        itemCount: products.length + 1,
        itemBuilder: (context, index) {
          if (index == products.length) return _footer(strings);
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () => widget.onOpenProduct(product.id),
          );
        },
      ),
    );
  }

  /// Dernière tuile de la grille : bouton « charger plus » ou fin de liste.
  Widget _footer(AppStrings strings) {
    final state = ref.watch(catalogControllerProvider);

    if (state.isLoadingMore) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!state.hasMore) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            strings.allProductsLoaded,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.tonalIcon(
          onPressed: ref.read(catalogControllerProvider.notifier).loadMore,
          icon: const Icon(Icons.expand_more),
          label: Text(strings.loadMore),
        ),
      ),
    );
  }
}
