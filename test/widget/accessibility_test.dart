import 'package:e_commerce_app/app/app.dart';
import 'package:e_commerce_app/core/di/providers.dart';
import 'package:e_commerce_app/core/l10n/app_strings.dart';
import 'package:e_commerce_app/core/storage/local_storage.dart';
import 'package:e_commerce_app/features/catalog/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api.dart';
import '../support/fake_json_cache_store.dart';
import '../support/fake_token_store.dart';
import '../support/mock_platform_channels.dart';

/// Garde-fou d'accessibilité.
///
/// Un `IconButton` sans `tooltip` et sans `Semantics` est un bouton que le
/// lecteur d'écran annonce seulement comme « bouton » : l'utilisateur ne sait
/// pas ce qu'il déclenche. Ce test parcourt l'arbre de sémantique réel de
/// chaque écran et échoue si un nœud actionnable n'a pas de nom.
///
/// Il porte sur les quatre onglets, pas sur un écran isolé : c'est ce que
/// rubriques l'utilisateur de la barre de navigation.
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

  /// Nœuds actionnables (bouton, case, interrupteur) sans nom accessible.
  /// Racines de tous les arbres de sémantique du test.
  ///
  /// Le `SemanticsOwner` est porté par le `ViewPipelineOwner`, qui est un
  /// *enfant* du `rootPipelineOwner` : le lire directement à la racine
  /// renverrait `null`. On parcourt donc la hiérarchie, comme le fait
  /// `flutter_test` lui-même pour ses propres finders sémantiques.
  List<SemanticsNode> semanticsRoots(WidgetTester tester) {
    final roots = <SemanticsNode>[];
    void collect(PipelineOwner owner) {
      final root = owner.semanticsOwner?.rootSemanticsNode;
      if (root != null) roots.add(root);
      owner.visitChildren(collect);
    }

    collect(tester.binding.rootPipelineOwner);
    return roots;
  }

  /// Noms annoncés par les nœuds actionnables (bouton, incrément,
  /// décrément), dans l'ordre de l'arbre.
  List<String> interactiveLabels(WidgetTester tester) {
    final roots = semanticsRoots(tester);
    if (roots.isEmpty) return const [];

    final names = <String>[];
    void visit(SemanticsNode node) {
      final data = node.getSemanticsData();
      final actionnable =
          data.hasAction(SemanticsAction.tap) ||
          data.hasAction(SemanticsAction.increase) ||
          data.hasAction(SemanticsAction.decrease);
      if (actionnable) {
        final label = data.label.trim();
        names.add(label.isNotEmpty ? label : data.tooltip.trim());
      }
      node.visitChildren((child) {
        visit(child);
        return true;
      });
    }

    for (final root in roots) {
      visit(root);
    }
    return names;
  }

  /// Nœuds actionnables (bouton, incrément, décrément) sans nom accessible.
  ///
  /// `Tooltip` ne remplit pas `label` mais `tooltip` : les deux sont annoncés
  /// par les lecteurs d'écran, l'un ou l'autre est donc acceptable. C'est le
  /// cas de tous les boutons à icône de l'application.
  List<String> unnamedInteractiveNodes(WidgetTester tester) {
    final roots = semanticsRoots(tester);
    if (roots.isEmpty) return const ['<aucun arbre de sémantique>'];

    final offenders = <String>[];
    void visit(SemanticsNode node) {
      final data = node.getSemanticsData();
      final actionnable =
          data.hasAction(SemanticsAction.tap) ||
          data.hasAction(SemanticsAction.increase) ||
          data.hasAction(SemanticsAction.decrease);
      if (actionnable) {
        final name = data.label.trim().isNotEmpty
            ? data.label.trim()
            : data.tooltip.trim();
        if (name.isEmpty) {
          offenders.add(
            'action sans nom — role: ${data.role}, hint: "${data.hint}"',
          );
        }
      }
      node.visitChildren((child) {
        visit(child);
        return true;
      });
    }

    for (final root in roots) {
      visit(root);
    }
    return offenders;
  }

  testWidgets('chaque bouton de l\'accueil porte un nom accessible', (
    tester,
  ) async {
    await login(tester);

    expect(unnamedInteractiveNodes(tester), isEmpty);

    // Une carte produit doit être annoncée par ce qui la décrit, pas par son
    // état de chargement : c'est le défaut que la vignette muette corrige.
    final labels = interactiveLabels(tester);
    expect(labels, isNotEmpty);
    expect(
      labels.where((label) => label.contains('iPhone 9')),
      isNotEmpty,
      reason: 'la tuile produit ne s\'annonce pas par son nom : $labels',
    );
    expect(
      labels,
      isNot(contains(const AppStrings(Locale('fr')).loading)),
      reason: 'une tuile est annoncée comme « Chargement… »',
    );
  });

  testWidgets('les boutons du panier portent un nom accessible', (
    tester,
  ) async {
    await login(tester);

    // Le panier est local : on y place un produit par le chemin réel
    // (fiche produit → ajout au panier) avant d'en contrôler les boutons.
    await tester.tap(find.byType(ProductCard).first);
    await settle(tester, steps: 20);
    await tester.tap(find.text('Ajouter au panier'));
    await settle(tester);
    await tester.tap(find.byTooltip('Retour'));
    await settle(tester);

    await tester.tap(find.text('Panier').last);
    await settle(tester, steps: 20);

    // Les boutons +/− et la suppression sont donc bien présents à l'écran.
    expect(find.text('iPhone 9'), findsWidgets);
    expect(unnamedInteractiveNodes(tester), isEmpty);
  });

  testWidgets(
    'les boutons des favoris et du compte portent un nom accessible',
    (tester) async {
      await login(tester);

      await tester.tap(find.byIcon(Icons.favorite_outline).last);
      await settle(tester, steps: 20);
      expect(unnamedInteractiveNodes(tester), isEmpty);

      await tester.tap(find.text('Mon compte').last);
      await settle(tester, steps: 20);
      expect(unnamedInteractiveNodes(tester), isEmpty);
    },
  );

  testWidgets('les boutons de la fiche produit portent un nom accessible', (
    tester,
  ) async {
    await login(tester);
    await tester.tap(find.byType(ProductCard).first);
    await settle(tester, steps: 20);

    expect(unnamedInteractiveNodes(tester), isEmpty);
  });

  testWidgets('l\'écran de connexion announces ses champs et ses boutons', (
    tester,
  ) async {
    await tester.pumpWidget(boot());
    await settle(tester);

    expect(unnamedInteractiveNodes(tester), isEmpty);
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
