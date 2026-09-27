import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/storage/token_store.dart';
import '../models/auth_response_dto.dart';
import '../models/user_dto.dart';

/// Accès aux endpoints d'authentification.
///
/// Unique couche où les URLs d'auth et la forme des payloads sont connues.
/// Elle ne contient aucune logique de cache ni de décision métier.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// `POST /auth/login` — échange identifiants contre un couple de jetons JWT.
  Future<AuthResponseDto> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.login(),
        data: {
          'username': username.trim(),
          'password': password,
          'expiresInMins': 60,
        },
      );
      return AuthResponseDto.fromJson(_unwrap(response.data));
    } on DioException catch (error) {
      throw ApiException(ErrorMapper.map(error));
    }
  }

  /// `POST /users/add` — création du profil utilisateur côté serveur.
  ///
  /// DummyJSON n'expose plus `POST /auth/signup` : la seule route de création
  /// disponible renvoie la fiche créée **sans** identifiants d'authentification.
  /// Le repository gère ce cas particulier.
  Future<UserDto> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.register(),
        data: {
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'email': email.trim(),
          'username': username.trim(),
          'password': password,
        },
      );
      return UserDto.fromJson(_unwrap(response.data));
    } on DioException catch (error) {
      throw ApiException(ErrorMapper.map(error));
    }
  }

  /// `GET /users/{id}` — profil complet de l'utilisateur authentifié.
  Future<UserDto> fetchProfile(int userId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.userById(userId),
      );
      return UserDto.fromJson(_unwrap(response.data));
    } on DioException catch (error) {
      throw ApiException(ErrorMapper.map(error));
    }
  }

  /// `POST /auth/refresh` — échange le refresh token contre un nouveau couple.
  ///
  /// Appelé via le client « nu » : cet appel ne doit jamais être intercepté,
  /// sinon un 401 déclencherait un nouveau refresh (boucle infinie).
  Future<TokenPair> refresh(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.refresh(),
        data: {'refreshToken': refreshToken},
      );
      final json = _unwrap(response.data);
      final access = json['accessToken'];
      final refresh = json['refreshToken'];
      if (access is! String || access.isEmpty) {
        throw const ApiException(
          ValidationFailure(debugMessage: 'Refresh response without token'),
        );
      }
      return TokenPair(
        accessToken: access,
        refreshToken: refresh is String && refresh.isNotEmpty
            ? refresh
            : refreshToken,
      );
    } on DioException catch (error) {
      throw ApiException(ErrorMapper.map(error));
    }
  }

  /// Certaines routes renvoient l'objet à la racine, d'autres l'enveloppent
  /// dans `{"user": ...}` ou `{"product": ...}`. On accepte les deux formes.
  Map<String, dynamic> _unwrap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      throw const ApiException(
        ValidationFailure(debugMessage: 'Empty auth payload'),
      );
    }
    if (data.containsKey('accessToken') || data.containsKey('user')) {
      return data;
    }
    for (final key in const ['user', 'data', 'product']) {
      final nested = data[key];
      if (nested is Map<String, dynamic>) return nested;
    }
    return data;
  }
}
