import 'package:e_commerce_app/core/error/error_mapper.dart';
import 'package:e_commerce_app/core/error/failure.dart';
import 'package:e_commerce_app/features/catalog/data/datasources/catalog_local_datasource.dart';
import 'package:e_commerce_app/features/catalog/data/datasources/catalog_remote_datasource.dart';
import 'package:e_commerce_app/features/catalog/data/models/product_dto.dart';
import 'package:e_commerce_app/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements CatalogRemoteDataSource {}

class _MockLocal extends Mock implements CatalogLocalDataSource {}

/// Vérifie la stratégie *network-first with cache fallback* du catalogue :
/// le repli local ne doit se produire que sur une panne de transport, jamais
/// sur une erreur renvoyée par le serveur.
void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late CatalogRepositoryImpl repository;

  setUpAll(() {
    // Mocktail a besoin d'un exemplaire « par défaut » de chaque type utilisé
    // dans un matcher `any(...)`.
    registerFallbackValue(_page());
    registerFallbackValue(_productDto());
  });

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    repository = CatalogRepositoryImpl(remote: remote, local: local);
  });

  group('getProducts', () {
    test('retourne les données réseau et écrit le cache', () async {
      when(
        () => remote.fetchProducts(
          limit: any(named: 'limit'),
          skip: any(named: 'skip'),
          query: any(named: 'query'),
          category: any(named: 'category'),
        ),
      ).thenAnswer((_) async => _page());
      when(
        () => local.cachePage(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          category: any(named: 'category'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.getProducts(limit: 20, skip: 0);

      expect(result.products, hasLength(1));
      expect(result.total, 1);
      await Future<void>.delayed(Duration.zero);
      verify(
        () => local.cachePage(page: any(named: 'page'), limit: 20),
      ).called(1);
    });

    test('replie sur la page en cache lors d’une panne réseau', () async {
      when(
        () => remote.fetchProducts(
          limit: any(named: 'limit'),
          skip: any(named: 'skip'),
          query: any(named: 'query'),
          category: any(named: 'category'),
        ),
      ).thenThrow(_offline());
      when(
        () => local.readPage(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          category: any(named: 'category'),
        ),
      ).thenAnswer((_) async => _page());

      final result = await repository.getProducts(limit: 20, skip: 0);

      expect(result.products.single.title, 'Test product');
    });

    test('propage l’erreur serveur sans lire le cache', () async {
      when(
        () => remote.fetchProducts(
          limit: any(named: 'limit'),
          skip: any(named: 'skip'),
          query: any(named: 'query'),
          category: any(named: 'category'),
        ),
      ).thenThrow(_server());

      await expectLater(
        repository.getProducts(limit: 20, skip: 0),
        throwsA(isA<ApiException>()),
      );
      verifyNever(
        () => local.readPage(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          category: any(named: 'category'),
        ),
      );
    });

    test('propage la panne réseau quand le cache est vide', () async {
      when(
        () => remote.fetchProducts(
          limit: any(named: 'limit'),
          skip: any(named: 'skip'),
          query: any(named: 'query'),
          category: any(named: 'category'),
        ),
      ).thenThrow(_offline());
      when(
        () => local.readPage(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          category: any(named: 'category'),
        ),
      ).thenAnswer((_) async => null);

      await expectLater(
        repository.getProducts(limit: 20, skip: 0),
        throwsA(isA<ApiException>()),
      );
    });

    test(
      'retombe sur la première page pour une recherche hors-ligne',
      () async {
        when(
          () => remote.fetchProducts(
            limit: any(named: 'limit'),
            skip: any(named: 'skip'),
            query: any(named: 'query'),
            category: any(named: 'category'),
          ),
        ).thenThrow(_offline());

        // Page 0 de la requête filtrée absente...
        when(
          () => local.readPage(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            category: any(named: 'category'),
          ),
        ).thenAnswer((invocation) async {
          final skip = invocation.namedArguments[#skip] as int;
          final limit = invocation.namedArguments[#limit] as int;
          final query = invocation.namedArguments[#query] as String?;
          // La page 20 (pagination) n'existe pas, la page 0 si.
          if (skip == 20) return null;
          expect(query, 'laptop');
          expect(limit, 20);
          return _page();
        });

        final result = await repository.getProducts(
          limit: 20,
          skip: 20,
          query: 'laptop',
        );

        expect(result.products, hasLength(1));
      },
    );
  });

  group('getProduct', () {
    test('met le détail en cache après un succès réseau', () async {
      when(() => remote.fetchProduct(7)).thenAnswer((_) async => _productDto());
      when(() => local.cacheProduct(any())).thenAnswer((_) async {});

      final product = await repository.getProduct(7);

      expect(product.id, 7);
      expect(product.discountedPrice, closeTo(80, 0.01));
      await Future<void>.delayed(Duration.zero);
      verify(() => local.cacheProduct(any())).called(1);
    });

    test('retourne la fiche en cache hors-ligne', () async {
      when(() => remote.fetchProduct(7)).thenThrow(_offline());
      when(() => local.readProduct(7)).thenAnswer((_) async => _productDto());

      final product = await repository.getProduct(7);

      expect(product.title, 'Test product');
    });

    test('propage un 404 même si une copie existe', () async {
      when(
        () => remote.fetchProduct(7),
      ).thenThrow(const ApiException(NotFoundFailure()));

      await expectLater(repository.getProduct(7), throwsA(isA<ApiException>()));
      verifyNever(() => local.readProduct(any()));
    });
  });

  group('getCategories', () {
    test('retourne les catégories du réseau', () async {
      when(() => remote.fetchCategories()).thenAnswer(
        (_) async => const [CategoryDto(slug: 'laptops', name: 'Laptops')],
      );
      when(() => local.cacheCategories(any())).thenAnswer((_) async {});

      final categories = await repository.getCategories();

      expect(categories.single.slug, 'laptops');
      expect(categories.single.displayName, 'Laptops');
    });

    test('retombe sur le cache des catégories hors-ligne', () async {
      when(() => remote.fetchCategories()).thenThrow(_offline());
      when(() => local.readCategories()).thenAnswer(
        (_) async => const [CategoryDto(slug: 'beauty', name: 'Beauty')],
      );

      final categories = await repository.getCategories();

      expect(categories.single.slug, 'beauty');
    });

    test('propage l’erreur si le cache des catégories est vide', () async {
      when(() => remote.fetchCategories()).thenThrow(_offline());
      when(() => local.readCategories()).thenAnswer((_) async => null);

      await expectLater(
        repository.getCategories(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  test('clearCache délègue à la source locale', () async {
    when(() => local.clear()).thenAnswer((_) async {});

    await repository.clearCache();

    verify(() => local.clear()).called(1);
  });
}

ApiException _offline() =>
    const ApiException(NetworkFailure(debugMessage: 'Connexion refusée'));

ApiException _server() => const ApiException(
  ServerFailure(statusCode: 500, debugMessage: 'Erreur serveur'),
);

ProductPageDto _page() =>
    ProductPageDto(products: [_productDto()], total: 1, skip: 0, limit: 20);

ProductDto _productDto() => const ProductDto(
  id: 7,
  title: 'Test product',
  description: 'Description',
  category: 'laptops',
  price: 100,
  discountPercentage: 20,
  rating: 4.5,
  stock: 12,
  thumbnail: 'https://example.test/7.png',
  images: ['https://example.test/7.png'],
);
