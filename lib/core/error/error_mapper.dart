import 'package:dio/dio.dart';

import 'failure.dart';

/// Exception applicative transportant une [Failure] typée.
///
/// Les data sources lèvent cette exception, les repositories la propagent, et
/// la couche présentation la convertit en `AsyncError`. Un seul type d'exception
/// traverse toute l'application : l'UI ne manipule donc jamais de `DioException`.
class ApiException implements Exception {
  const ApiException(this.failure);

  final Failure failure;

  String get code => failure.code;

  @override
  String toString() => 'ApiException(${failure.code})';
}

/// Convertit une exception Dio (ou une erreur inattendue) en [Failure].
///
/// Point d'entrée unique de la gestion d'erreurs réseau : toute l'application
/// passe par ici, ce qui garantit qu'aucun message technique brut ne fuit.
abstract final class ErrorMapper {
  static Failure map(Object error) {
    if (error is ApiException) return error.failure;
    if (error is DioException) return _fromDio(error);
    if (error is FormatException) {
      return const ValidationFailure(debugMessage: 'Malformed JSON payload');
    }
    if (error is TypeError || error is ArgumentError) {
      return const ValidationFailure(debugMessage: 'Unexpected payload shape');
    }
    return UnknownFailure(debugMessage: error.runtimeType.toString());
  }

  static Failure _fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return NetworkFailure(debugMessage: 'Timeout: ${error.type.name}');
      case DioExceptionType.connectionError:
        return const NetworkFailure(debugMessage: 'Connection error');
      case DioExceptionType.cancel:
        return const CancelledFailure(debugMessage: 'Cancelled by caller');
      case DioExceptionType.badCertificate:
        return const NetworkFailure(debugMessage: 'Bad TLS certificate');
      case DioExceptionType.badResponse:
        return _fromResponse(error.response);
      case DioExceptionType.unknown:
        final cause = error.error;
        if (cause is FormatException) {
          return const ValidationFailure(debugMessage: 'Malformed payload');
        }
        return NetworkFailure(
          debugMessage: 'Unknown transport error: ${error.message}',
        );
    }
  }

  static Failure _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode ?? 0;
    final serverMessage = _extractMessage(response?.data);

    return switch (status) {
      400 || 409 || 422 => ValidationFailure(
        debugMessage: serverMessage ?? 'HTTP $status',
        fieldErrors: _extractFieldErrors(response?.data),
      ),
      401 ||
      403 => UnauthorizedFailure(debugMessage: serverMessage ?? 'HTTP $status'),
      404 => NotFoundFailure(debugMessage: serverMessage ?? 'HTTP $status'),
      >= 500 => ServerFailure(
        statusCode: status,
        debugMessage: serverMessage ?? 'HTTP $status',
      ),
      _ => UnknownFailure(debugMessage: serverMessage ?? 'HTTP $status'),
    };
  }

  /// Extrait le champ `message` des API JSON (DummyJSON, Supabase, ...).
  static String? _extractMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      for (final key in const ['message', 'error', 'error_description']) {
        final value = data[key];
        if (value is String && value.isNotEmpty) return value;
      }
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        final nested = error['message'];
        if (nested is String && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }

  /// Extrait un dictionnaire d'erreurs par champ pour l'affichage inline.
  static Map<String, String> _extractFieldErrors(Object? data) {
    if (data is! Map<String, dynamic>) return const {};

    final result = <String, String>{};
    for (final key in const ['errors', 'fieldErrors', 'fields']) {
      final block = data[key];
      if (block is Map<String, dynamic>) {
        for (final entry in block.entries) {
          final value = entry.value;
          result[entry.key] = value is List && value.isNotEmpty
              ? value.first.toString()
              : value.toString();
        }
        return result;
      }
    }
    return result;
  }
}
