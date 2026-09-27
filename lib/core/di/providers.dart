import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/catalog/data/datasources/catalog_local_datasource.dart';
import '../../features/catalog/data/datasources/catalog_remote_datasource.dart';
import '../../features/catalog/data/repositories/catalog_repository_impl.dart';
import '../../features/catalog/domain/repositories/catalog_repository.dart';
import '../../features/orders/data/datasources/orders_local_datasource.dart';
import '../../features/orders/data/datasources/orders_remote_datasource.dart';
import '../../features/orders/data/repositories/orders_repository_impl.dart';
import '../../features/orders/domain/repositories/orders_repository.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../storage/credential_store.dart';
import '../storage/local_storage.dart';
import '../storage/token_store.dart';

/// Racine de composition de l'application.
///
/// Toutes les dépendances longue durée sont construites ici et injectées par
/// Riverpod. L'ordre de lecture résout le cycle `TokenStore → Repository →
/// Intercepteur` sans aucune variable globale ni état statique :
///
/// ```text
/// tokenStore ─┐
///             ├─► AuthRepositoryImpl ──► dioProvider (avec AuthInterceptor)
/// bareDio ────┘        (AuthTokenRefresher)
/// ```

// ---------------------------------------------------------------------------
// Stockage
// ---------------------------------------------------------------------------

/// Boîtes Hive ouvertes au démarrage. Surchargée dans `main()` via
/// `ProviderScope(overrides: [...])` ; une valeur par défaut explicite évite un
/// `null` silencieux si l'initialisation a été oubliée.
final localStorageProvider = Provider<LocalStorage>(
  (ref) => throw UnimplementedError(
    'localStorageProvider must be overridden in ProviderScope. '
    'Call `await LocalStorage.init()` before runApp().',
  ),
);

final secureStorageProvider = Provider<FlutterSecureStorage>(
  // Depuis la v11, le chiffrement au repos (AES-GCM + enveloppement de clé RSA
  // via le KeyStore) est le comportement par défaut : plus aucun
  // `encryptedSharedPreferences` n'est requis.
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(),
  ),
);

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => SecureTokenStore(ref.watch(secureStorageProvider)),
);

/// Comptes créés depuis l'application. L'API de démonstration n'authentifie
/// que des comptes pré-chargés : ce dépôt rend ces comptes réutilisables.
final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => SecureCredentialStore(ref.watch(secureStorageProvider)),
);

// ---------------------------------------------------------------------------
// Réseau
// ---------------------------------------------------------------------------

/// Client sans intercepteur d'authentification.
///
/// Utilisé par la feature `auth` : les routes `/auth/*` n'exigent pas de jeton,
/// et surtout le refresh ne doit jamais ré-entrer dans l'intercepteur, sous
/// peine de boucle infinie.
final bareDioProvider = Provider<Dio>((ref) => ApiClient.createBare());

/// Incrémenté par l'intercepteur lorsque le refresh échoue. Le contrôleur
/// d'authentification l'observe et force la déconnexion.
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

/// Client applicatif : injecte le jeton et assure sa rotation sur 401.
final dioProvider = Provider<Dio>((ref) {
  return ApiClient.create(
    tokenStore: ref.watch(tokenStoreProvider),
    refresher: ref.watch(authTokenRefresherProvider),
    onSessionExpired: () {
      final notifier = ref.read(sessionExpiredProvider.notifier);
      notifier.state = notifier.state + 1;
    },
  );
});

/// Flux de connectivité, base du bandeau « mode hors-ligne ».
///
/// `connectivity_plus` n'a pas d'implémentation sur toutes les plateformes
/// cibles (Linux bureau, environnement de test) : l'absence de détecteur est
/// transformée en flux vide, donc en « en ligne », au lieu de laisser remonter
/// une `MissingPluginException` non gérée qui ferait échouer le test de fumée
/// et bruiterait la console sur un poste non connecté au réseau.
/// La détection reste un simple confort d'affichage : la stratégie offline
/// s'appuie sur le cache, jamais sur l'état du détecteur.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  const online = <ConnectivityResult>[];
  final controller = StreamController<List<ConnectivityResult>>();

  // `connectivity_plus` n'a pas d'implémentation sur toutes les plateformes
  // cibles : l'activation du canal peut échouer de façon synchrone, avant même
  // que `handleError` ne puisse voir l'erreur. L'écoute est donc enveloppée
  // dans un `try`/`catch` et le flux de secours annonce « en ligne » : la
  // stratégie offline s'appuie sur le cache, jamais sur ce détecteur.
  controller.onListen = () {
    try {
      Connectivity().onConnectivityChanged.listen(
        controller.add,
        onError: (Object _) => controller.add(online),
        cancelOnError: false,
      );
    } catch (_) {
      controller.add(online);
    }
  };

  ref.onDispose(controller.close);
  return controller.stream;
});

/// `true` lorsque l'appareil n'a aucune connexion utilisable.
final isOfflineProvider = Provider<bool>((ref) {
  final results = ref.watch(connectivityProvider).valueOrNull;
  if (results == null || results.isEmpty) return false;
  return results.every((r) => r == ConnectivityResult.none);
});

// ---------------------------------------------------------------------------
// Feature : authentification
// ---------------------------------------------------------------------------

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(bareDioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    credentialStore: ref.watch(credentialStoreProvider),
    cache: ref.watch(localStorageProvider).profile,
  ),
);

/// Vue minimale dont l'intercepteur Dio a besoin pour renouveler un jeton.
///
/// Ce `cast` est sûr et volontairement isolé ici : il est la seule fois où le
/// graphe de dépendances connaît un rôle d'implémentation. Les couches
/// supérieures ne dépendent que de [AuthRepository].
final authTokenRefresherProvider = Provider<AuthTokenRefresher>(
  (ref) => ref.watch(authRepositoryProvider) as AuthTokenRefresher,
);

// ---------------------------------------------------------------------------
// Feature : catalogue
// ---------------------------------------------------------------------------

final catalogRemoteDataSourceProvider = Provider<CatalogRemoteDataSource>(
  (ref) => CatalogRemoteDataSource(ref.watch(dioProvider)),
);

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepositoryImpl(
    remote: ref.watch(catalogRemoteDataSourceProvider),
    local: CatalogLocalDataSource(ref.watch(localStorageProvider).products),
  ),
);

// ---------------------------------------------------------------------------
// Feature : commandes
// ---------------------------------------------------------------------------

final ordersRemoteDataSourceProvider = Provider<OrdersRemoteDataSource>(
  (ref) => OrdersRemoteDataSource(ref.watch(dioProvider)),
);

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepositoryImpl(
    remote: ref.watch(ordersRemoteDataSourceProvider),
    local: OrdersLocalDataSource(ref.watch(localStorageProvider).orders),
  ),
);
