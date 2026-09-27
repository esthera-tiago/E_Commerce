import '../entities/app_user.dart';

/// Contrat d'accès aux données d'authentification.
///
/// Défini dans le domaine, implémenté dans `data`. Cette inversion de
/// dépendance permet à la couche présentation de tester ses vues avec un
/// faux repository, sans toucher au réseau.
abstract interface class AuthRepository {
  /// Restaure la session au démarrage de l'application à partir des jetons
  /// chiffrés. Retourne `null` si l'utilisateur n'est pas authentifié.
  Future<AppUser?> restoreSession();

  /// Authentifie un existant. Lève [ApiException] en cas d'échec.
  Future<AppUser> login({required String username, required String password});

  /// Crée un compte puis authentifie le nouvel utilisateur. Lève
  /// [ApiException] en cas d'échec.
  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
  });

  /// Renvoie le profil complet depuis l'API (`GET /users/{id}`).
  /// Lève [ApiException] en cas d'échec.
  Future<AppUser> fetchProfile(int userId);

  /// Supprime les jetons et purge le cache associé à l'utilisateur.
  Future<void> logout();

  /// `true` si un couple de jetons valide est présent sur l'appareil.
  Future<bool> hasSession();
}
