import '../../../../core/storage/token_store.dart';
import 'user_dto.dart';

/// Réponse d'authentification : l'utilisateur **et** ses deux jetons JWT.
///
/// `POST /auth/login` et `POST /auth/refresh` partagent ce format.
///
/// Cette classe ne participe **pas** à la mise en cache : voir
/// `AuthRepositoryImpl._persistProfile`, seul le profil est écrit dans Hive,
/// les jetons allant dans le `TokenStore` chiffré.
class AuthResponseDto {
  const AuthResponseDto({required this.user, required this.tokens});

  final UserDto user;
  final TokenPair tokens;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      user: UserDto.fromJson(json),
      tokens: TokenPair(
        accessToken: (json['accessToken'] as String?) ?? '',
        refreshToken: (json['refreshToken'] as String?) ?? '',
      ),
    );
  }

  /// Identifiant utilisateur porté par le jeton d'accès.
  ///
  /// Permet d'appeler `GET /users/{id}` sans faire un second aller-retour.
  int? get userId {
    final id = tokens.accessPayload?['id'];
    return id is num ? id.toInt() : null;
  }
}
