import 'dart:async';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_review.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_local_datasource.dart';
import '../datasources/catalog_remote_datasource.dart';

/// Repository du catalogue — cœur de la stratégie **offline-first**.
///
/// Stratégie *network-first with cache fallback* :
///
/// ```text
///        ┌─ réseau OK ──►  écriture du cache  ──►  retour données fraîches
/// requête┤
///        └─ réseau KO ──►  lecture du cache    ──►  retour données en cache
///                              │
///                              └─ cache vide ──►  ApiException (UI affiche l'erreur)
/// ```
///
/// Seules les pannes réseau basculent vers le cache. Une erreur serveur (5xx)
/// ou une validation (4xx) reste une vraie erreur : l'utilisateur doit voir ce
/// que le serveur dit plutôt que des données potentiellement périmées.
class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl({
    required CatalogRemoteDataSource remote,
    required CatalogLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  final CatalogRemoteDataSource _remote;
  final CatalogLocalDataSource _local;

  @override
  Future<ProductPage> getProducts({
    int limit = AppConfig.catalogPageSize,
    int skip = 0,
    String? query,
    String? category,
  }) async {
    try {
      final page = await _remote.fetchProducts(
        limit: limit,
        skip: skip,
        query: query,
        category: category,
      );
      // Write-through : le cache est mis à jour pendant que l'utilisateur
      // consulte la réponse, pour un mode hors-ligne complet et immediat.
      unawaited(
        _local.cachePage(
          page: page,
          limit: limit,
          query: query,
          category: category,
        ),
      );
      return page.toEntity();
    } on ApiException catch (error) {
      if (!_isOffline(error)) rethrow;
      final cached = await _fallbackPage(
        limit: limit,
        skip: skip,
        query: query,
        category: category,
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<Product> getProduct(int id) async {
    try {
      final dto = await _remote.fetchProduct(id);
      unawaited(_local.cacheProduct(dto));
      return dto.toEntity();
    } on ApiException catch (error) {
      if (_isOffline(error)) {
        final cached = await _local.readProduct(id);
        if (cached != null) return cached.toEntity();
      }
      rethrow;
    }
  }

  @override
  Future<List<ProductCategory>> getCategories() async {
    try {
      final categories = await _remote.fetchCategories();
      unawaited(_local.cacheCategories(categories));
      return categories.map((c) => c.toEntity()).toList();
    } on ApiException catch (error) {
      if (_isOffline(error)) {
        final cached = await _local.readCategories();
        if (cached != null && cached.isNotEmpty) {
          return cached.map((c) => c.toEntity()).toList();
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> clearCache() => _local.clear();

  /// `true` si l'échec vient du transport et non du serveur.
  ///
  /// Un 404 ou un 500 ne doit jamais être masqué par des données en cache :
  /// l'utilisateur verrait un catalogue plausible mais faux.
  bool _isOffline(ApiException error) =>
      error.failure is NetworkFailure || error.failure is CancelledFailure;

  /// Cherche une copie en cache de la page demandée.
  ///
  /// En cas de recherche hors-ligne, la page 0 de la requête correspondante est
  /// proposée : c'est le comportement attendu d'une recherche en mode avion.
  /// La condition porte sur `skip > 0` car relire `skip: 0` avec les mêmes
  /// filtres ne ferait que renvoyer l'entrée absente que l'on vient d'échouer
  /// à lire.
  Future<ProductPage?> _fallbackPage({
    required int limit,
    required int skip,
    String? query,
    String? category,
  }) async {
    final exact = await _local.readPage(
      skip: skip,
      limit: limit,
      query: query,
      category: category,
    );
    if (exact != null && exact.products.isNotEmpty) return exact.toEntity();

    if (skip > 0 && (query != null || category != null)) {
      final firstPage = await _local.readPage(
        skip: 0,
        limit: limit,
        query: query,
        category: category,
      );
      if (firstPage != null && firstPage.products.isNotEmpty) {
        return firstPage.toEntity();
      }
    }
    return null;
  }
}
