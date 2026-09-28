import 'package:e_commerce_app/app/app.dart';
import 'package:e_commerce_app/core/di/providers.dart';
import 'package:e_commerce_app/core/storage/local_storage.dart';
import 'package:e_commerce_app/features/catalog/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api.dart';
import '../support/fake_json_cache_store.dart';
import '../support/fake_token_store.dart';
import '../support/mock_platform_channels.dart';

/// Contrat hors-ligne du catalogue, de la connexion au navigateur.
///
/// L'application est *network-first with cache fallback* : le catalogue ne
///Consult* le cache que sur une panne réseau, jamais sur un 5xx. Ce parcours
/// vérifie la promesse faite à l'utilisateur qui ouvre l'application dans un
/// train sans réseau — il doit voir ses produits, pas une erreur.
void main() {
  late FakeApi api;
  late FakeTokenStore tokens;
  late List<FakeJsonCacheStore> caches;
  late FakeConnectivity connectivity;

  setUp(() {
    connectivity = mockConnectivityChannel();
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

  testWidgets('le catalogue reste lisible quand le réseau tombe', (
    tester,
  ) async {
    // Première exécution : connecté, le cache se remplit.
    await login(tester);
    expect(find.text('iPhone 9'), findsOneWidget);
    expect(caches[0].entries, isNotEmpty);

    // Coupure réseau annoncée par la plateforme, puis redémarrage de
    // l'application avec la même session.
    api.offline = true;
    connectivity.goOffline();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(boot());
    await settle(tester, steps: 20);

    // Le catalogue vient du cache : l'utilisateur voit ses produits, et sait
    // pourquoi il ne voit pas les nouveautés.
    expect(find.text('iPhone 9'), findsOneWidget);
    expect(find.text('iPad Air'), findsOneWidget);

    // Le bandeau d'appareil est repéré par son icône : la même phrase est
    // aussi reprise par une notice affichée dans le catalogue, et l'assertion
    // ne doit pas dépendre du nombre de messages présents à l'écran.
    // Deux signaux distincts préviennent l'utilisateur : le bandeau d'appareil,
    // sous la barre d'état, et la notice du catalogue qui sert les données en
    // cache. Les deux doivent disparaître quand le réseau revient.
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.textContaining('Hors-ligne'), findsNWidgets(2));

    // Le retour du réseau efface le bandeau sans toucher au catalogue affiché.
    api.offline = false;
    connectivity.goOnline();
    await settle(tester, steps: 6);
    expect(find.byIcon(Icons.wifi_off), findsNothing);

    // Seule la puce « tout » subsiste : les catégories viennent de l'API et ne
    // sont pas mises en cache, donc le filtre disparaît hors-ligne.
    expect(find.byType(FilterChip), findsOneWidget);
    expect(
      find.widgetWithText(FilterChip, 'Toutes les catégories'),
      findsOneWidget,
    );

    // En revanche les actions locales restent disponibles : le panier est
    // entièrement sur l'appareil.
    await tester.tap(find.byType(ProductCard).first);
    await settle(tester, steps: 20);
    await tester.tap(find.text('Ajouter au panier'));
    await settle(tester);
    await tester.tap(find.byTooltip('Retour'));
    await settle(tester, steps: 20);

    final cached = caches[4].entries['cart_items']! as List<dynamic>;
    expect(cached, hasLength(1));
    expect(find.text('Panier'), findsWidgets);
  });

  testWidgets('sans cache ni réseau, l\'erreur est expliquée', (tester) async {
    api.offline = true;

    await tester.pumpWidget(boot());
    await settle(tester, steps: 12);

    // Aucun jeton : l'application doit s'arrêter sur la connexion, pas
    // inventer un catalogue.
    expect(find.text('Ravi de vous revoir'), findsOneWidget);
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
