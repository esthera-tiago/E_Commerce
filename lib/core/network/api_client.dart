import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_store.dart';
import 'auth_interceptor.dart';

/// Fabrique du client Dio partagé par toutes les data sources.
///
/// Deux instances sont produites :
/// - [create] — le client applicatif, équipé de l'[AuthInterceptor] ;
/// - [createBare] — un client sans intercepteur d'authentification, réservé au
///   seul appel de refresh token (pour ne pas déclencher de récursion) et aux
///   tests unitaires.
abstract final class ApiClient {
  static Dio create({
    required TokenStore tokenStore,
    required AuthTokenRefresher refresher,
    required void Function() onSessionExpired,
    String baseUrl = AppConfig.apiBaseUrl,
  }) {
    final dio = createBare(baseUrl: baseUrl);

    dio.interceptors.add(
      AuthInterceptor(
        tokenStore: tokenStore,
        refresher: refresher,
        onSessionExpired: onSessionExpired,
        client: createBare(baseUrl: baseUrl),
      ),
    );

    return dio;
  }

  static Dio createBare({String baseUrl = AppConfig.apiBaseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        responseType: ResponseType.json,
        headers: const {'Accept': 'application/json'},
        // Tout statut >= 400 est converti en DioException, puis en `Failure`,
        // afin que la gestion d'erreur reste centralisée dans l'ErrorMapper.
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: false,
          logPrint: (o) => debugPrint('[API] $o'),
        ),
      );
    }

    return dio;
  }
}
