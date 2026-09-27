import 'package:dio/dio.dart';

import '../storage/token_store.dart';

/// Contrat de renouvellement de jeton, implémenté par la couche `auth`.
///
/// Ce découplage évite que le cœur réseau connaisse la feature `auth` : le
/// noyau ne sait que « quelqu'un sait renouveler un jeton ».
abstract interface class AuthTokenRefresher {
  /// Renvoie un couple de jetons neuf, ou `null` si le renouvellement est
  /// impossible (refresh token expiré/révoqué) et que l'utilisateur doit se
  /// reconnecter.
  Future<TokenPair?> refresh();
}

/// Intercepteur Dio responsable de deux choses :
///
/// 1. **Injection du jeton** — ajoute `Authorization: Bearer <accessToken>` à
///    chaque requête sortante lorsque l'utilisateur est authentifié.
/// 2. **Rotation du jeton** — sur une réponse `401`, appelle
///    [AuthTokenRefresher] une seule fois (même sous rafale de requêtes
///    parallèles), rejoue la requête échouée avec le nouveau jeton, et déconnecte
///    l'utilisateur si le refresh échoue.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStore tokenStore,
    required AuthTokenRefresher refresher,
    required void Function() onSessionExpired,
    Dio? client,
  }) : _tokenStore = tokenStore,
       _refresher = refresher,
       _onSessionExpired = onSessionExpired,
       _rawClient = client;

  final TokenStore _tokenStore;
  final AuthTokenRefresher _refresher;
  final void Function() _onSessionExpired;

  /// Client « nu » (sans intercepteurs) dédié au refresh, afin d'éviter toute
  /// récursion : le refresh ne doit jamais déclencher un nouveau refresh.
  final Dio? _rawClient;

  /// Verrou d'exclusion mutuelle : garantit qu'une rafale de `401` simultanés
  /// ne provoque qu'un seul appel à `POST /auth/refresh`.
  Future<TokenPair?>? _refreshInFlight;

  /// Chemins sur lesquels aucun jeton ne doit être envoyé.
  static const _unauthenticatedPaths = {
    '/auth/login',
    '/auth/signup',
    '/auth/refresh',
  };

  static const _authorizationHeader = 'Authorization';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isUnauthenticated(options.path)) {
      handler.next(options);
      return;
    }

    final pair = _tokenStore.current;
    if (pair != null && pair.accessToken.isNotEmpty) {
      options.headers[_authorizationHeader] = 'Bearer ${pair.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final isAuthRoute = _isUnauthenticated(request.path);

    // Un 401 sur /auth/* est une erreur d'identifiants : il ne doit jamais
    // déclencher de boucle de refresh.
    if (err.response?.statusCode != 401 || isAuthRoute) {
      handler.next(err);
      return;
    }

    // Garde-fou anti-boucle : si la requête porte déjà le jeton issu d'un
    // refresh, on abandonne plutôt que de boucler indéfiniment.
    if (request.headers[_authorizationHeader] !=
        'Bearer ${_tokenStore.current?.accessToken}') {
      handler.next(err);
      return;
    }

    try {
      final pair = await _refreshOnce();
      if (pair == null) {
        await _tokenStore.clear();
        _onSessionExpired();
        handler.next(err);
        return;
      }

      request.headers[_authorizationHeader] = 'Bearer ${pair.accessToken}';
      final response = await _rawClient!.fetch<dynamic>(request);
      handler.resolve(response);
    } on Object {
      // Le refresh lui-même a échoué : la session est considérée perdue.
      await _tokenStore.clear();
      _onSessionExpired();
      handler.next(err);
    }
  }

  /// Dédoublonne les appels concurrents au refresh.
  Future<TokenPair?> _refreshOnce() {
    return _refreshInFlight ??= _refresher.refresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  bool _isUnauthenticated(String path) =>
      _unauthenticatedPaths.any((p) => path.endsWith(p));
}
