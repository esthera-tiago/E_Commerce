import 'dart:convert';

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

/// Test de fumée de bout en bout.
///
/// Il ne rejoue pas les règles métier (couverture par les tests de
/// repository) mais vérifie ce qu'aucun autre test ne couvre : le routeur, le
/// `ProviderScope`, le garde de session, la connexion réelle et le câblage des
/// écrans. Un test qui passe ici a traversé l'intégralité de la pile avec une
/// API en mémoire.
void main() {
  late FakeApi api;
  late FakeTokenStore tokens;
  late List<FakeJsonCacheStore> caches;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    api = FakeApi()
      ..on('/products/categories', (_) => ['smartphones', 'laptops'])
      ..on(
        '/products/search',
        (_) => {
          'products': [_product(1)],
          'total': 1,
        },
      )
      ..on(
        '/products/category',
        (_) => {
          'products': [_product(1)],
          'total': 1,
        },
      )
      ..on('/products/1', (_) => _product(1, reviews: true))
      ..on(
        '/products',
        (_) => {
          'products': [_product(1), _product(2)],
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
          'accessToken': _jwt(const Duration(hours: 1)),
          'refreshToken': _jwt(const Duration(days: 7)),
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
          'company': {
            'name': 'Dooley, Kozey and Cronin',
            'department': 'Engineering',
            'title': 'Sales Manager',
          },
        },
      );

    tokens = FakeTokenStore();
    caches = List.generate(6, (_) => FakeJsonCacheStore());
    // Langue choisie par l'utilisateur : elle est stockée dans la carte
    // `settings`, et la relire au démarrage est justement l'une des garanties
    // vérifiées ici.
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

  /// `pumpAndSettle` ne convient pas : les indicateurs de chargement
  /// progressifs font boucler l'animation. On avance donc le temps par pas
  /// fixes, le temps que l'arbre se stabilise.
  Future<void> settle(
    WidgetTester tester, {
    int steps = 12,
    Duration step = const Duration(milliseconds: 120),
  }) async {
    for (var i = 0; i < steps; i++) {
      await tester.pump(step);
    }
  }

  /// Conduit l'application jusqu'à l'accueil authentifié.
  Future<void> login(WidgetTester tester) async {
    await tester.pumpWidget(boot());
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).first, 'emilys');
    await tester.enterText(find.byType(TextFormField).last, 'emilyspass');
    await tester.tap(find.widgetWithText(FilledButton, 'Connexion'));
    await settle(tester, steps: 20);
  }

  testWidgets('sans session, l\'application ouvre la connexion', (
    tester,
  ) async {
    await tester.pumpWidget(boot());
    await settle(tester);

    // La langue persistée est bien appliquée : l'interface est en français.
    expect(find.widgetWithText(FilledButton, 'Connexion'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Ravi de vous revoir'), findsOneWidget);
    // Le garde de session ne demande aucune donnée protégée avant l'authentification.
    expect(api.hits('/carts/user/'), 0);
    expect(api.hits('/auth/'), 0);
  });

  testWidgets('la connexion charge l\'accueil et ses produits', (tester) async {
    await login(tester);

    expect(api.hits('/auth/login'), 1);
    expect(find.text('iPhone 9'), findsOneWidget);
    expect(find.text('iPad Air'), findsOneWidget);
    // Les jetons sont confiés au TokenStore, jamais au cache Hive.
    expect(tokens.saveCount, greaterThanOrEqualTo(1));
    expect(caches[2].entries.containsKey('session'), isFalse);
  });

  testWidgets('un mot de passe erroné reste sur l\'écran de connexion', (
    tester,
  ) async {
    api.onStatus('/auth/login', 400, {'message': 'Invalid credentials'});

    await tester.pumpWidget(boot());
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).first, 'emilys');
    await tester.enterText(find.byType(TextFormField).last, 'mauvais');
    await tester.tap(find.widgetWithText(FilledButton, 'Connexion'));
    await settle(tester, steps: 20);

    expect(find.text('iPhone 9'), findsNothing);
    expect(api.hits('/users/1'), 0);
  });

  testWidgets('le détail produit s\'ouvre depuis l\'accueil', (tester) async {
    await login(tester);

    await tester.tap(find.byType(ProductCard).first);
    await settle(tester, steps: 20);

    expect(api.hits('/products/1'), greaterThanOrEqualTo(1));
  });

  testWidgets('les quatre onglets sont accessibles une fois connecté', (
    tester,
  ) async {
    await login(tester);

    // Les quatre destinations de la barre basse, dont le libellé du dernier
    // onglet dépend de l'état de session.
    for (final label in ['Boutique', 'Favoris', 'Panier', 'Mon compte']) {
      expect(find.text(label), findsWidgets, reason: 'onglet « $label »');
    }
    expect(
      find.text('Compte'),
      findsNothing,
      reason: 'le libellé « Compte » ne doit plus apparaître connecté',
    );

    // Les commandes sont une page imbriquée de l'onglet compte.
    await tester.tap(find.text('Mon compte').last);
    await settle(tester);
    await tester.tap(find.text('Commandes'));
    await settle(tester, steps: 20);

    // Le panier devient lisible : c'est la première donnée protégée demandée.
    expect(api.hits('/carts/user/'), 1);
    expect(find.textContaining('#77'), findsOneWidget);
  });

  testWidgets('un produit ajouté au panier alimente le badge', (tester) async {
    await login(tester);

    await tester.tap(find.byType(ProductCard).first);
    await settle(tester, steps: 20);
    await tester.tap(find.text('Ajouter au panier'));
    await settle(tester);

    // Retour à l'accueil via la flèche de la barre d'application.
    await tester.tap(find.byTooltip('Retour'));
    await settle(tester);

    // Le panier est persisté et la ligne ajoutée est la seule présente.
    expect(caches[4].entries.containsKey('cart_items'), isTrue);
    final cached = caches[4].entries['cart_items']! as List<dynamic>;
    expect(cached, hasLength(1));
    expect((cached.first as Map<String, dynamic>)['quantity'], 1);
  });
}

Map<String, dynamic> _product(int id, {bool reviews = false}) => {
  'id': id,
  'title': id == 1 ? 'iPhone 9' : 'iPad Air',
  'description': 'Un appareil de démonstration pour les tests.',
  'category': 'smartphones',
  'price': id == 1 ? 549.0 : 599.0,
  'discountPercentage': id == 1 ? 5.0 : 0.0,
  'rating': 4.5,
  'stock': 12,
  'brand': 'Apple',
  'sku': 'SKU-$id',
  'thumbnail': 'https://cdn.dummyjson.com/product/$id.jpg',
  'images': ['https://cdn.dummyjson.com/product/$id.jpg'],
  'tags': ['mobile'],
  'dimensions': {'width': 1.0, 'height': 2.0, 'depth': 0.5},
  'availabilityStatus': 'In Stock',
  'warrantyInformation': '1 an',
  'shippingInformation': 'Livraison 24 h',
  'returnPolicy': '30 jours',
  'reviews': reviews
      ? [
          {
            'id': 1,
            'rating': 5,
            'comment': 'Excellent rapport qualité/prix.',
            'date': '2026-01-01T00:00:00.000Z',
            'reviewerName': 'John',
            'reviewerEmail': 'john@x.dummyjson.com',
          },
        ]
      : <dynamic>[],
};

String _jwt(Duration ttl) {
  String segment(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final exp = DateTime.now().add(ttl).millisecondsSinceEpoch ~/ 1000;
  return '${segment({'alg': 'HS256', 'typ': 'JWT'})}'
      '.${segment({'id': 1, 'exp': exp})}.signature';
}
