import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../error/error_mapper.dart';
import '../error/failure.dart';

/// Paire de jetons JWT renvoyée par `POST /auth/login` et `POST /auth/refresh`.
class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  /// Lit la charge utile (payload) du JWT sans vérification de signature.
  ///
  /// Sert uniquement à détecter un jeton déjà expiré et donc à éviter un aller-
  /// retour réseau inutile. La validation réelle reste le rôle du serveur.
  Map<String, dynamic>? get accessPayload => _decodeJwt(accessToken);

  Map<String, dynamic>? get refreshPayload => _decodeJwt(refreshToken);

  /// `true` si le `exp` du jeton d'accès est dépassé.
  bool get isAccessExpired {
    final exp = accessPayload?['exp'];
    if (exp is! num) return false;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp.toInt();
  }

  static Map<String, dynamic>? _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      // `base64Url.normalize` ne fait que re-padder la chaîne ; le décodage
      // effectif est réalisé par `base64Url.decode` + `utf8.decode`.
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      return jsonDecode(payload) as Map<String, dynamic>;
    } on Object {
      return null;
    }
  }
}

/// Stockage chiffré des jetons d'authentification.
///
/// `flutter_secure_storage` s'appuie sur le Keychain iOS et le EncryptedShared
/// Preferences Android : les jetons ne sont jamais écrits en clair sur disque,
/// contrairement à `shared_preferences`.
abstract interface class TokenStore {
  /// Lecture synchrone du couple de jetons en mémoire, utilisé par
  /// l'intercepteur pour injecter l'en-tête `Authorization`.
  TokenPair? get current;

  Future<TokenPair?> read();

  Future<void> save(TokenPair pair);

  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';

  TokenPair? _memo;

  @override
  TokenPair? get current => _memo;

  @override
  Future<TokenPair?> read() async {
    try {
      final access = await _storage.read(key: _accessKey);
      final refresh = await _storage.read(key: _refreshKey);
      if (access == null || refresh == null || refresh.isEmpty) return null;
      return _memo = TokenPair(accessToken: access, refreshToken: refresh);
    } on Object catch (error) {
      throw ApiException(ErrorMapper.map(error));
    }
  }

  @override
  Future<void> save(TokenPair pair) async {
    try {
      await _storage.write(key: _accessKey, value: pair.accessToken);
      await _storage.write(key: _refreshKey, value: pair.refreshToken);
      _memo = pair;
    } on Object {
      throw const ApiException(
        CacheFailure(debugMessage: 'Unable to persist access token'),
      );
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
      _memo = null;
    } on Object {
      throw const ApiException(
        CacheFailure(debugMessage: 'Unable to clear access token'),
      );
    }
  }
}
