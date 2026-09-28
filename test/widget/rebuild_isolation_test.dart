import 'package:e_commerce_app/app/app.dart';
import 'package:e_commerce_app/core/di/providers.dart';
import 'package:e_commerce_app/core/storage/local_storage.dart';
import 'package:e_commerce_app/features/cart/presentation/cart_controller.dart';
import 'package:e_commerce_app/features/catalog/presentation/catalog_controller.dart';
import 'package:e_commerce_app/features/catalog/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api.dart';
import '../support/fake_json_cache_store.dart';
import '../support/fake_token_store.dart';
import '../support/mock_platform_channels.dart';

/// Garde-fou de performance : changer un produit ne doit pas réveiller la
/// grille entière.
///
/// Observer l'état complet du panier ou le tuple complet des favoris depuis
/// chaque tuile était correct mais coûteux : le moindre changement reconstrui-
/// sait les vingt cellules, y compris celles qui n'ont rien à afficher. Ce test
/// compte les reconstructions réellement publiées par le framework
/// (`debugPrintRebuildDirtyWidgets`) : il échoue si une tuile voisine se
/// reconstruit, ce qu'aucune assertion sur l'interface ne détecterait.
void main() {
  late FakeApi api;
  late FakeTokenStore tokens;
  late List<FakeJsonCacheStore> caches;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    api = FakeApi()
      ..on('/products/categories', (_) => ['smartphones'])
      ..on(
        '/products/search',
        (_) => {
          'products': [_product],
          'total': 1,
        },
      )
      ..on(
        '/products/category',
        (_) => {
          'products': [_product],
          'total': 1,
        },
      )
      ..on('/products/1', (_) => _product)
      ..on(
        '/products',
        (_) => {
          'products': [_product, _second],
          'total': 2,
          'skip': 0,
          'limit': 20,
        },
      )
      ..on(
        '/carts/user/',
        (_) => {
          'carts': [
            {
              'id': 77,
              'userId': 1,
              'products': [
                {
                  'id': 1,
                  'title': 'iPhone 9',
                  'price': 549,
                  'quantity': 2,
                  'total': 1098,
                  'discountedTotal': 1043.1,
                  'discountPercentage': 5,
                  'thumbnail':
                      'https://cdn.dummyjson.com/product/apple-iphone-9.jpg',
                },
              ],
              'total': 1098,
              'discountedTotal': 1043.1,
              'totalQuantity': 2,
            },
          ],
          'total': 1,
        },
      )
      ..on(
        '/auth/login',
        (_) => {
          'id': 1,
          'username': 'emilys',
          'email': 'emily.johnson@x.dummyjson.com',
          'firstName': 'Emily',
          'lastName': 'Johnson',
          'image': 'https://cdn.dummyjson.com/icon/emilys/128.png',
          'accessToken': 'header.payload.signature',
          'refreshToken': 'header.payload.signature',
        },
      )
      ..on(
        '/users/1',
        (_) => {
          'id': 1,
          'username': 'emilys',
          'email': 'emily.johnson@x.dummyjson.com',
          'firstName': 'Emily',
          'lastName': 'Johnson',
          'phone': '+1 319 555 5555',
          'image': 'https://cdn.dummyjson.com/icon/emilys/128.png',
        },
      );

    tokens = FakeTokenStore();
    caches = List.generate(6, (_) => FakeJsonCacheStore());
    caches[5].write('settings', {'settings_locale': 'fr'});
  });

  Widget boot() {
    final storage = LocalStorage.forTesting(
      products: caches[0],
      orders: caches[1],
      profile: caches[2],
      favorites: caches[3],
      cart: caches[4],
      preferences: caches[5],
    );
    return ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        tokenStoreProvider.overrideWithValue(tokens),
        credentialStoreProvider.overrideWithValue(FakeCredentialStore()),
        dioProvider.overrideWithValue(api.dio()),
        bareDioProvider.overrideWithValue(api.dio()),
      ],
      child: const ECommerceApp(),
    );
  }

  Future<void> settle(
    WidgetTester tester, {
    int steps = 12,
    Duration step = const Duration(milliseconds: 120),
  }) async {
    for (var i = 0; i < steps; i++) {
      await tester.pump(step);
    }
  }

  Future<void> login(WidgetTester tester) async {
    await tester.pumpWidget(boot());
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).first, 'emilys');
    await tester.enterText(find.byType(TextFormField).last, 'emilyspass');
    await tester.tap(find.widgetWithText(FilledButton, 'Connexion'));
    await settle(tester, steps: 20);
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(ECommerceApp)),
        listen: false,
      );

  /// Exécute [action] et renvoie le nombre de `ProductCard` reconstruites.
  ///
  /// Le hook `debugOnRebuildDirtyWidget` est appelé par le framework pour chaque
  /// widget marqué « à reconstruire » : on compte donc les vraies
  /// reconstructions, sans dépendre du format d'un message de log.
  Future<int> countRebuildsWhile(Future<void> Function() action) async {
    var count = 0;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (element.widget is ProductCard) count++;
    };

    try {
      await action();
    } finally {
      debugOnRebuildDirtyWidget = null;
    }

    return count;
  }

  testWidgets('basculer un favori ne reconstruit que sa tuile', (tester) async {
    await login(tester);
    await settle(tester);
    expect(find.byType(ProductCard), findsNWidgets(2));

    final rebuilt = await countRebuildsWhile(() async {
      await tester.tap(
        find
            .descendant(
              of: find.byType(ProductCard).first,
              matching: find.byIcon(Icons.favorite_outline),
            )
            .first,
      );
      await settle(tester, steps: 4);
    });

    expect(
      rebuilt,
      1,
      reason: 'un favori a réveillé toute la grille : $rebuilt',
    );
  });

  testWidgets('ajouter au panier ne reconstruit que la tuile du produit', (
    tester,
  ) async {
    await login(tester);
    await settle(tester);
    expect(find.byType(ProductCard), findsNWidgets(2));

    final container = containerOf(tester);
    // Le panier rendu par l'API contient l'iPhone 9 : cet ajout porte sa
    // quantité de 2 à 3, et ne change rien pour l'iPad Air.
    final iphone = container
        .read(catalogControllerProvider)
        .visibleProducts
        .firstWhere((product) => product.id == 1);

    final rebuilt = await countRebuildsWhile(() async {
      container.read(cartControllerProvider.notifier).add(iphone);
      await settle(tester, steps: 4);
    });

    expect(
      rebuilt,
      1,
      reason: 'le panier a réveillé des tuiles sans rapport : $rebuilt',
    );
  });
}

Map<String, dynamic> _product = {
  'id': 1,
  'title': 'iPhone 9',
  'description': 'Un appareil de démonstration pour les tests.',
  'category': 'smartphones',
  'price': 549.0,
  'discountPercentage': 5.0,
  'rating': 4.5,
  'stock': 12,
  'brand': 'Apple',
  'sku': 'SKU-1',
  'thumbnail': 'https://cdn.dummyjson.com/product/1.jpg',
  'images': ['https://cdn.dummyjson.com/product/1.jpg'],
  'tags': ['mobile'],
  'dimensions': {'width': 1.0, 'height': 2.0, 'depth': 0.5},
  'availabilityStatus': 'In Stock',
  'warrantyInformation': '1 an',
  'shippingInformation': 'Livraison 24 h',
  'returnPolicy': '30 jours',
  'reviews': <dynamic>[],
};

Map<String, dynamic> _second = {..._product, 'id': 2, 'title': 'iPad Air'};
