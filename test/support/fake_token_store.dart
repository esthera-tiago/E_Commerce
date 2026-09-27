import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:e_commerce_app/core/storage/credential_store.dart';
import 'package:e_commerce_app/core/storage/token_store.dart';

/// `TokenStore` en mémoire.
///
/// Le test doit pouvoir prétendre « il existe une session valide » ou « la
/// session vient d'expirer » sans passer par `flutter_secure_storage`, qui
/// n'existe pas sur la plateforme de test.
class FakeTokenStore implements TokenStore {
  FakeTokenStore([this._pair]);

  TokenPair? _pair;

  int saveCount = 0;
  int clearCount = 0;

  /// Simule une rotation de jetons réussie.
  set pair(TokenPair? value) => _pair = value;

  /// Miroir synchrone utilisé par l'intercepteur pour l'en-tête `Authorization`.
  @override
  TokenPair? get current => _pair;

  @override
  Future<TokenPair?> read() async => _pair;

  @override
  Future<void> save(TokenPair pair) async {
    _pair = pair;
    saveCount++;
  }

  @override
  Future<void> clear() async {
    _pair = null;
    clearCount++;
  }
}

/// `CredentialStore` en mémoire.
///
/// Reproduit le comportement qui compte pour l'authentification : le verdict
/// distingue l'utilisateur inconnu du mot de passe erroné, ce qui permet à
/// `AuthRepositoryImpl` de ne proposer le repli local qu'après un refus
/// explicite de l'API.
class FakeCredentialStore implements CredentialStore {
  FakeCredentialStore([Map<String, String>? accounts])
    : _accounts = {...?accounts};

  final Map<String, String> _accounts;
  final Map<String, Map<String, dynamic>> _profiles = {};
  final List<String> deleted = [];

  String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  @override
  Future<void> save({
    required String username,
    required String password,
    required Map<String, dynamic> profile,
  }) async {
    final key = username.trim().toLowerCase();
    _accounts[key] = _hash(password);
    _profiles[key] = profile;
  }

  @override
  Future<CredentialCheck> verify({
    required String username,
    required String password,
  }) async {
    final stored = _accounts[username.trim().toLowerCase()];
    if (stored == null) return CredentialCheck.unknownUser;
    return stored == _hash(password)
        ? CredentialCheck.valid
        : CredentialCheck.wrongPassword;
  }

  @override
  Future<bool> exists(String username) async =>
      _accounts.containsKey(username.trim().toLowerCase());

  @override
  Future<Map<String, dynamic>?> readProfile(String username) async =>
      _profiles[username.trim().toLowerCase()];

  @override
  Future<void> delete(String username) async {
    final key = username.trim().toLowerCase();
    _accounts.remove(key);
    _profiles.remove(key);
    deleted.add(key);
  }
}
