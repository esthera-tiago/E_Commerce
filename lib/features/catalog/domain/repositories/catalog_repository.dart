import '../entities/product.dart';
import '../entities/product_review.dart';

/// Contrat d'accès au catalogue.
///
/// Implémenté par `CatalogRepositoryImpl`, qui applique la stratégie
/// *network-first avec repli sur le cache* : c'est cette interface qui rend le
/// mode hors-ligne testable indépendamment du réseau.
abstract interface class CatalogRepository {
  /// charge une page de produits, éventuellement filtrée par [query] (recherche
  /// plein texte) ou [category] (slug de catégorie).
  Future<ProductPage> getProducts({
    int limit,
    int skip,
    String? query,
    String? category,
  });

  /// Détail d'un produit, avec ses avis clients.
  Future<Product> getProduct(int id);

  /// Liste des catégories disponibles.
  Future<List<ProductCategory>> getCategories();

  /// Purge le cache du catalogue.
  Future<void> clearCache();
}
