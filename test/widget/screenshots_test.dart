import 'dart:convert';

import 'package:e_commerce_app/app/app.dart';
import 'package:e_commerce_app/core/di/providers.dart';
import 'package:e_commerce_app/core/storage/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api.dart';
import '../support/fake_json_cache_store.dart';
import '../support/fake_token_store.dart';
import '../support/mock_platform_channels.dart';

/// Capture les écrans de l'application dans `Screnshots/`.
///
/// Les fichiers sont régénérés avec :
///
/// ```sh
/// flutter test test/app/screenshots_test.dart --update-goldens
/// ```
///
/// Le test sert aussi de garde-fou : un écran qui déborde ou qui lève une
/// exception fait échouer la génération, ce qui n'arriverait pas d'un script de
/// capture qui ignorerait les erreurs.
void main() {
  late FakeApi api;
  late FakeTokenStore tokens;
  late List<FakeJsonCacheStore> caches;

  setUpAll(() {
    // iPhone 13/14 Pro : 390 x 844 pt, densité 3.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    api = _fakeApi();
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

  Future<void> settle(WidgetTester tester, {int steps = 16}) async {
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> login(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).first, 'emilys');
    await tester.enterText(find.byType(TextFormField).last, 'emilyspass');
    await tester.tap(find.widgetWithText(FilledButton, 'Connexion'));
    await settle(tester, steps: 24);
  }

  void usePhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('01 connexion', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(boot());
    await settle(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../Screnshots/01-connexion.png'),
    );
  });

  testWidgets('02 catalogue', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(boot());
    await settle(tester);
    await login(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../Screnshots/02-catalogue.png'),
    );
  });

  testWidgets('03 fiche produit', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(boot());
    await settle(tester);
    await login(tester);
    await tester.tap(find.text(_titles.first));
    await settle(tester, steps: 24);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../Screnshots/03-produit.png'),
    );
  });

  testWidgets('04 panier', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(boot());
    await settle(tester);
    await login(tester);
    await tester.tap(find.text(_titles.first));
    await settle(tester, steps: 24);
    await tester.tap(find.text('Ajouter au panier'));
    await settle(tester);
    await tester.tap(find.byTooltip('Retour'));
    await settle(tester);
    await tester.tap(find.text('Panier'));
    await settle(tester, steps: 20);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../Screnshots/04-panier.png'),
    );
  });

  testWidgets('05 commandes', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(boot());
    await settle(tester);
    await login(tester);
    await tester.tap(find.text('Mon compte').last);
    await settle(tester, steps: 20);
    await tester.tap(find.text('Commandes'));
    await settle(tester, steps: 24);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../Screnshots/05-commandes.png'),
    );
  });

  testWidgets('06 compte', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(boot());
    await settle(tester);
    await login(tester);
    await tester.tap(find.text('Mon compte').last);
    await settle(tester, steps: 20);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../Screnshots/06-compte.png'),
    );
  });
}

const _thumbnails = <String>[
  'https://cdn.dummyjson.com/product-images/1/thumbnail.webp',
  'https://cdn.dummyjson.com/product-images/2/thumbnail.webp',
  'https://cdn.dummyjson.com/product-images/3/thumbnail.webp',
];

const _titles = <String>[
  'Essence Mascara Lash Princess',
  'Eyeshadow Palette with Mirror',
  'Powder Canister',
];

FakeApi _fakeApi() => FakeApi()
  ..on('/products/categories', (_) => ['smartphones', 'laptops', 'tablets'])
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
              'title': _titles.first,
              'price': 549,
              'quantity': 2,
              'total': 1098,
              'discountedTotal': 1043.1,
              'discountPercentage': 5,
              'thumbnail': _thumbnails.first,
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

Map<String, dynamic> _product(int id, {bool reviews = false}) => {
  'id': id,
  'title': _titles[id - 1],
  'description':
      'Un appareil de démonstration lengkap pour illustrer la fiche produit.',
  'category': 'smartphones',
  'price': id == 1 ? 549.0 : 599.0,
  'discountPercentage': id == 1 ? 5.0 : 0.0,
  'rating': 4.5,
  'stock': 12,
  'brand': 'Essence',
  'sku': 'SKU-$id',
  'thumbnail': 'https://cdn.dummyjson.com/product-images/$id/thumbnail.webp',
  'images': ['https://cdn.dummyjson.com/product-images/$id/thumbnail.webp'],
  'tags': ['mobile'],
  'dimensions': {'width': 1.0, 'height': 2.0, 'depth': 0.5},
  'availabilityStatus': 'In Stock',
  'warrantyInformation': '1 an de garantie',
  'shippingInformation': 'Livraison sous 24 h',
  'returnPolicy': 'Retours acceptés sous 30 jours',
  'reviews': reviews
      ? [
          {
            'id': 1,
            'rating': 5,
            'comment': 'Excellent rapport qualité/prix.',
            'date': '2026-01-01T00:00:00.000Z',
            'reviewerName': 'John Doe',
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
