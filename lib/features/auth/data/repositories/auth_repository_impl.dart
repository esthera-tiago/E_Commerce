import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/storage/credential_store.dart';
import '../../../../core/storage/json_cache_store.dart';
import '../../../../core/storage/token_store.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response_dto.dart';
import '../models/user_dto.dart';

/// Implémentation du repository d'authentification.
///
/// Responsabilités :
/// - persistre les jetons **chiffrés** ([TokenStore]) — jamais en clair, et
///   jamais dans le cache Hive ;
/// - mettre en cache le profil pour un démarrage hors-ligne ;
/// - implémenter [AuthTokenRefresher] pour alimenter l'intercepteur Dio.
///
/// ## Deux origines de session
///
/// L'API de démonstration ne permet pas d'émettre un jeton pour un compte
/// nouvellement créé (voir [CredentialStore]). Une session peut donc être
/// établie de deux façons :
///
/// | Source | Jeton JWT | Données |
/// |--------|-----------|---------|
/// | Compte pré-chargé par l'API | oui | API + cache |
/// | Compte créé sur cet appareil | non | API + cache |
///
/// Toutes les routes de données DummyJSON (`/products`, `/carts`, `/users`)
/// étant publiques, la seconde session reste pleinement fonctionnelle.
class AuthRepositoryImpl implements AuthRepository, AuthTokenRefresher {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStore tokenStore,
    required CredentialStore credentialStore,
    required JsonCacheStore cache,
  }) : _remote = remote,
       _tokenStore = tokenStore,
       _credentialStore = credentialStore,
       _cache = cache;

  final AuthRemoteDataSource _remote;
  final TokenStore _tokenStore;
  final CredentialStore _credentialStore;
  final JsonCacheStore _cache;

  static const _profileCacheKey = 'auth_profile';
  static const _activeUserKey = 'auth_active_username';

  /// Origine de la session courante : `api` pour un couple de jetons JWT,
  /// `local` pour un compte créé sur cet appareil, `none` après une
  /// déconnexion.
  ///
  /// Sans cette distinction, un profil resterait « connecté » alors que ses
  /// jetons ont expiré : `hasSession()` ne verrait plus que le cache et
  /// laisserait passer l'utilisateur sur des requêtes qui échoueront en 401.
  static const _sessionKindKey = 'auth_session_kind';

  static const _kindApi = 'api';
  static const _kindLocal = 'local';

  @override
  Future<bool> hasSession() async {
    if (await _tokenStore.read() case final pair?) {
      // Un refresh token expiré signifie qu'aucune reconnexion automatique
      // n'est possible : inutile de considérer la session comme active.
      final exp = pair.refreshPayload?['exp'];
      if (exp is num &&
          DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp.toInt()) {
        await _tokenStore.clear();
      } else {
        return true;
      }
    }
    // Session locale (compte créé sur l'appareil) : elle reste valable tant que
    // le profil est en cache et que le marqueur de session le confirme. Un
    // profil laissé par une session API dont les jetons ont expiré ne compte
    // pas.
    if (await _cache.read<String>(_sessionKindKey) != _kindLocal) return false;
    return await _cache.read<Map<String, dynamic>>(_profileCacheKey) != null;
  }

  @override
  Future<AppUser?> restoreSession() async {
    if (!await hasSession()) return null;

    // Démarrage hors-ligne : on relit le profil depuis le cache local. Les
    // jetons, eux, ne transitent jamais par Hive.
    final cached = await _cache.read<Map<String, dynamic>>(_profileCacheKey);
    if (cached == null) return null;
    return UserDto.fromCache(cached).toEntity();
  }

  @override
  Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    final normalised = username.trim();

    // 1. Compte connu de l'API → vrai couple de jetons JWT.
    try {
      final response = await _remote.login(
        username: normalised,
        password: password,
      );
      return _persistSession(response);
    } on ApiException catch (error) {
      // Le repli local ne concerne que les refus de l'API (400/401/403) : une
      // panne réseau ou une erreur 5xx doit remonter telle quelle, sinon
      // l'utilisateur verrait « identifiants invalides » au lieu de la vraie
      // cause.
      if (!_isCredentialRejection(error.failure)) rethrow;
    }

    // 2. Compte créé sur cet appareil.
    final verdict = await _credentialStore.verify(
      username: normalised,
      password: password,
    );
    switch (verdict) {
      case CredentialCheck.unknownUser:
        throw const ApiException(
          UnauthorizedFailure(debugMessage: 'Unknown user'),
        );
      case CredentialCheck.wrongPassword:
        throw const ApiException(
          UnauthorizedFailure(debugMessage: 'Wrong password'),
        );
      case CredentialCheck.valid:
        break;
    }

    final profile = await _credentialStore.readProfile(normalised);
    if (profile == null) {
      throw const ApiException(
        CacheFailure(debugMessage: 'Local profile missing'),
      );
    }
    return _persistProfile(UserDto.fromCache(profile), tokens: null);
  }

  @override
  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
  }) async {
    final normalised = username.trim();

    if (await _credentialStore.exists(normalised)) {
      throw const ApiException(
        ValidationFailure(debugMessage: 'Username already taken'),
      );
    }

    // L'utilisateur est réellement créé côté serveur, ce qui rend l'écran
    // d'inscription connected à l'API plutôt qu'à un simple formulaire local.
    final created = await _remote.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      username: normalised,
      password: password,
    );

    await _credentialStore.save(
      username: normalised,
      password: password,
      profile: created.toJson(),
    );
    return _persistProfile(created, tokens: null);
  }

  @override
  Future<AppUser> fetchProfile(int userId) async {
    try {
      final dto = await _remote.fetchProfile(userId);
      // Seul le profil est mis en cache : aucun jeton n'est écrit dans Hive.
      await _cache.write(_profileCacheKey, dto.toJson());
      return dto.toEntity();
    } on ApiException catch (error) {
      // Hors-ligne : on dégrade vers le profil mis en cache plutôt que
      // d'afficher une erreur à l'utilisateur.
      if (error.failure is NetworkFailure) {
        final cached = await _cache.read<Map<String, dynamic>>(
          _profileCacheKey,
        );
        if (cached != null) return UserDto.fromCache(cached).toEntity();
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _tokenStore.clear();
    await _cache.remove(_profileCacheKey);
    await _cache.remove(_activeUserKey);
    // Le marqueur d'origine est indispensable : sans lui, le profil restant
    // en cache ferait passer `hasSession()` pour une session locale.
    await _cache.remove(_sessionKindKey);
  }

  @override
  Future<TokenPair?> refresh() async {
    final pair = await _tokenStore.read();
    if (pair == null || pair.refreshToken.isEmpty) return null;

    try {
      final renewed = await _remote.refresh(pair.refreshToken);
      await _tokenStore.save(renewed);
      return renewed;
    } on ApiException {
      // Refresh refusé ou expiré : la session ne peut pas être renouvelée.
      // L'intercepteur enverra alors `onSessionExpired` à la couche UI.
      return null;
    }
  }

  /// Persiste une session servie par l'API : jetons chiffrés + profil en cache.
  Future<AppUser> _persistSession(AuthResponseDto response) async {
    if (response.tokens.accessToken.isEmpty ||
        response.tokens.refreshToken.isEmpty) {
      throw const ApiException(
        ValidationFailure(debugMessage: 'Auth response without token'),
      );
    }
    return _persistProfile(response.user, tokens: response.tokens);
  }

  /// Point d'écriture unique du profil : c'est ici, et uniquement ici, qu'on
  /// décide ce qui va dans le stockage chiffré et ce qui va dans le cache.
  Future<AppUser> _persistProfile(
    UserDto user, {
    required TokenPair? tokens,
  }) async {
    try {
      if (tokens != null) await _tokenStore.save(tokens);
      await _cache.write(_profileCacheKey, user.toJson());
      await _cache.write(_activeUserKey, user.username);
      await _cache.write(
        _sessionKindKey,
        tokens == null ? _kindLocal : _kindApi,
      );
    } on ApiException {
      rethrow;
    } on Object catch (error) {
      throw ApiException(ErrorMapper.map(error));
    }
    return user.toEntity();
  }

  /// `true` quand l'API a explicitement refusé le couple identifiants /
  /// mot de passe, et qu'un compte local peut donc être recherché.
  bool _isCredentialRejection(Failure failure) =>
      failure is ValidationFailure ||
      failure is UnauthorizedFailure ||
      failure is NotFoundFailure;
}
