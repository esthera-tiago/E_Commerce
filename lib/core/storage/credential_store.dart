import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Verdict de la vérification d'un mot de passe local.
enum CredentialCheck {
  /// Le couple correspond à un compte créé sur cet appareil.
  valid,

  /// Aucun compte local ne porte ce nom d'utilisateur.
  unknownUser,

  /// Le compte existe mais le mot de passe est incorrect.
  wrongPassword,
}

/// Dépôt local des comptes créés depuis l'application.
///
/// ## Pourquoi ce composant existe
///
/// L'API de démonstration n'expose pas de création de compte exploitable :
/// `POST /auth/signup` répond 404 et `POST /users/add` crée une fiche
/// utilisateur **sans** identifiants d'authentification (un `POST /auth/login`
/// avec ce couple est rejeté en 400). Les comptes de session ne sont donc que
/// ceux pré-chargés par l'API.
///
/// Plutôt que de rendre l'écran d'inscription inopérant, l'application crée
/// réellement l'utilisateur côté API puis conserve une empreinte du mot de
/// passe **chiffrée** sur l'appareil, ce qui permet à ce compte de se
/// reconnecter. Aucun mot de passe en clair n'est écrit sur le disque.
///
/// Le contrat de [AuthRepository] ne change pas : brancher un vrai backend
/// consiste à remplacer cette classe, sans toucher à l'interface.
abstract interface class CredentialStore {
  Future<void> save({
    required String username,
    required String password,
    required Map<String, dynamic> profile,
  });

  Future<CredentialCheck> verify({
    required String username,
    required String password,
  });

  Future<bool> exists(String username);

  /// Profil mis en cache lors de l'inscription, relu lors des connexions
  /// suivantes sans appel réseau.
  Future<Map<String, dynamic>?> readProfile(String username);

  Future<void> delete(String username);
}

class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _profilePrefix = 'local_profile_';
  static const _hashPrefix = 'local_hash_';
  static const _saltPrefix = 'local_salt_';

  @override
  Future<void> save({
    required String username,
    required String password,
    required Map<String, dynamic> profile,
  }) async {
    final salt = _randomSalt();
    await _storage.write(
      key: '$_hashPrefix$username',
      value: _hash(salt, password),
    );
    await _storage.write(key: '$_saltPrefix$username', value: salt);
    await _storage.write(
      key: '$_profilePrefix$username',
      value: jsonEncode(profile),
    );
  }

  @override
  Future<CredentialCheck> verify({
    required String username,
    required String password,
  }) async {
    final salt = await _storage.read(key: '$_saltPrefix$username');
    final expected = await _storage.read(key: '$_hashPrefix$username');
    if (salt == null || expected == null) return CredentialCheck.unknownUser;

    final actual = _hash(salt, password);
    // Comparaison à temps constant : évite de révéler le préfixe correct par
    // mesure du temps de réponse.
    if (!_constantTimeEquals(actual, expected)) {
      return CredentialCheck.wrongPassword;
    }
    return CredentialCheck.valid;
  }

  @override
  Future<bool> exists(String username) async {
    final salt = await _storage.read(key: '$_saltPrefix$username');
    return salt != null;
  }

  @override
  Future<Map<String, dynamic>?> readProfile(String username) async {
    final raw = await _storage.read(key: '$_profilePrefix$username');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> delete(String username) async {
    await _storage.delete(key: '$_hashPrefix$username');
    await _storage.delete(key: '$_saltPrefix$username');
    await _storage.delete(key: '$_profilePrefix$username');
  }

  /// SHA-256 salé. L'empreinte n'est jamais réversible ; le sel, tiré par
  /// [Random.secure], empêche deux comptes d'un même mot de passe de produire
  /// la même valeur.
  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt::$password')).toString();

  String _randomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
