import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'json_cache_store.dart';

/// Conteneur des boîtes Hive ouvertes au démarrage.
///
/// Les boîtes sont ouvertes **une seule fois** dans `main()` puis injectées via
/// un `ProviderScope.overrideWithValue`. Ce choix évite :
/// - des `FutureProvider` imbriqués dans le graphe Riverpod ;
/// - des reconstructions de repository à chaque lecture ;
/// - tout état global statique, ce qui garde l'application testable.
class LocalStorage {
  LocalStorage._({
    required this.products,
    required this.orders,
    required this.profile,
    required this.favorites,
    required this.cart,
    required this.preferences,
  });

  /// Catalogue produits (pages + détails + catégories).
  final JsonCacheStore products;

  /// Commandes de l'utilisateur.
  final JsonCacheStore orders;

  /// Session et profil.
  final JsonCacheStore profile;

  /// Identifiants de produits favoris.
  final JsonCacheStore favorites;

  /// Contenu du panier local.
  final JsonCacheStore cart;

  /// Préférences (thème, langue, notifications).
  final JsonCacheStore preferences;

  /// Variante construite à la main, utilisée par les tests.
  ///
  /// `init()` est le seul chemin en production, mais il exige un répertoire
  /// Hive réel. Exposer cette fabrique permet de tester le graphe Riverpod
  /// complet (écrans, routeur, repositories) avec des caches en mémoire, sans
  /// écrire sur disque ni dépendre de la plateforme.
  @visibleForTesting
  factory LocalStorage.forTesting({
    required JsonCacheStore products,
    required JsonCacheStore orders,
    required JsonCacheStore profile,
    required JsonCacheStore favorites,
    required JsonCacheStore cart,
    required JsonCacheStore preferences,
  }) => LocalStorage._(
    products: products,
    orders: orders,
    profile: profile,
    favorites: favorites,
    cart: cart,
    preferences: preferences,
  );

  static Future<LocalStorage> init() async {
    await Hive.initFlutter();
    return LocalStorage._(
      products: await JsonCacheStore.open('products_cache'),
      orders: await JsonCacheStore.open('orders_cache'),
      profile: await JsonCacheStore.open('profile_cache'),
      favorites: await JsonCacheStore.open('favorites_cache'),
      cart: await JsonCacheStore.open('cart_cache'),
      preferences: await JsonCacheStore.open('preferences_cache'),
    );
  }

  /// Vide toutes les boîtes sans les fermer (déconnexion, « effacer mes
  /// données »).
  Future<void> clearAll() async {
    await products.clear();
    await orders.clear();
    await profile.clear();
    await favorites.clear();
    await cart.clear();
    await preferences.clear();
  }
}
