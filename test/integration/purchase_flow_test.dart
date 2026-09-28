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

/// Parcours d'achat de bout en bout, sur l'application entière.
///
/// Les tests unitaires vérifient chaque pièce séparément ; celui-ci vérifie
/// l'enchaînement que vit l'utilisateur — connexion, fiche produit, panier,
/// confirmation — et l'effet durable sur le stockage. Une régression qui casse
/// la transmission du produit au panier ou le vidage après commande se voit
/// ici, même si tous les tests unitaires restent verts.
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

  testWidgets('un achat complet se fait de la connexion au panier vidé', (
    tester,
  ) async {
    await login(tester);
    expect(find.text('iPhone 9'), findsOneWidget);

    // Fiche produit : le produit choisi doit survivre à la navigation.
    await tester.tap(find.byType(ProductCard).first);
    await settle(tester, steps: 20);
    expect(find.text('Ajouter au panier'), findsOneWidget);

    await tester.tap(find.text('Ajouter au panier'));
    await settle(tester);
    await tester.tap(find.byTooltip('Retour'));
    await settle(tester);

    // Le panier contient la ligne choisie, avec la quantité attendue.
    await tester.tap(find.text('Panier').last);
    await settle(tester, steps: 20);
    expect(find.text('iPhone 9'), findsWidgets);

    final cachedBefore = caches[4].entries['cart_items']! as List<dynamic>;
    expect(cachedBefore, hasLength(1));
    expect((cachedBefore.first as Map<String, dynamic>)['quantity'], 1);

    // Le bouton de la page et celui du dialogue portent le même libellé : on
    // cible le dialogue explicitement, sinon on recliquerait le bouton masqué
    // derrière la barrière modale.
    final confirmButton = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, 'Commander'),
    );

    // Confirmation : le dialogue récapitule avant de vider le panier.
    await tester.tap(find.widgetWithText(FilledButton, 'Commander').first);
    await settle(tester);
    expect(confirmButton, findsOneWidget);
    expect(find.text('Commande confirmée'), findsNothing);

    await tester.tap(confirmButton);
    await settle(tester);
    expect(find.text('Commande confirmée'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Commander').last);
    await settle(tester);

    // Le panier est vidé et l'information persiste : c'est ce que relira le
    // prochain lancement de l'application.
    expect(find.text('Votre panier est vide.'), findsOneWidget);
    final cachedAfter = caches[4].entries['cart_items']! as List<dynamic>;
    expect(cachedAfter, isEmpty);
  });

  testWidgets('le panier survit à un redémarrage puis se vide à la commande', (
    tester,
  ) async {
    await login(tester);
    await tester.tap(find.byType(ProductCard).first);
    await settle(tester, steps: 20);
    await tester.tap(find.text('Ajouter au panier'));
    await settle(tester);

    // Redémarrage : nouvelle arborescence, même stockage.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(boot());
    await settle(tester, steps: 20);

    await tester.tap(find.text('Panier').last);
    await settle(tester, steps: 20);
    expect(find.text('iPhone 9'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Commander').first);
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Commander').last);
    await settle(tester);

    expect(caches[4].entries['cart_items'], isEmpty);
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
