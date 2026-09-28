import 'package:dio/dio.dart';
import 'package:e_commerce_app/core/error/error_mapper.dart';
import 'package:e_commerce_app/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';

/// `ErrorMapper` est le point de conversion unique entre Dio et le domaine :
/// ces tests verrouillent le contrat dont dépend toute la stratégie offline.
void main() {
  DioException dioError(
    DioExceptionType type, {
    int statusCode = 0,
    Object? data,
  }) => DioException(
    requestOptions: RequestOptions(path: '/test'),
    type: type,
    response: statusCode == 0
        ? null
        : Response<dynamic>(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: statusCode,
            data: data,
          ),
  );

  group('types de transport', () {
    test('les délais expirent en NetworkFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ]) {
        expect(
          ErrorMapper.map(dioError(type)),
          isA<NetworkFailure>(),
          reason: '$type doit permettre le repli sur le cache',
        );
      }
    });

    test('une erreur de connexion permet le repli cache', () {
      expect(
        ErrorMapper.map(dioError(DioExceptionType.connectionError)),
        isA<NetworkFailure>(),
      );
    });

    test('une annulation est distinguée d’une panne réseau', () {
      expect(
        ErrorMapper.map(dioError(DioExceptionType.cancel)),
        isA<CancelledFailure>(),
      );
    });
  });

  group('réponses HTTP', () {
    test('400/409/422 deviennent des erreurs de validation', () {
      for (final status in [400, 409, 422]) {
        final failure = ErrorMapper.map(
          dioError(DioExceptionType.badResponse, statusCode: status),
        );
        expect(failure, isA<ValidationFailure>(), reason: 'HTTP $status');
      }
    });

    test('401/403 deviennent des erreurs d’autorisation', () {
      for (final status in [401, 403]) {
        expect(
          ErrorMapper.map(
            dioError(DioExceptionType.badResponse, statusCode: status),
          ),
          isA<UnauthorizedFailure>(),
          reason: 'HTTP $status',
        );
      }
    });

    test('404 devient NotFoundFailure', () {
      expect(
        ErrorMapper.map(
          dioError(DioExceptionType.badResponse, statusCode: 404),
        ),
        isA<NotFoundFailure>(),
      );
    });

    test('5xx devient ServerFailure et conserve le statut', () {
      final failure = ErrorMapper.map(
        dioError(DioExceptionType.badResponse, statusCode: 503),
      );

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 503);
    });

    test('le message du serveur alimente le champ de debug', () {
      final failure = ErrorMapper.map(
        dioError(
          DioExceptionType.badResponse,
          statusCode: 400,
          data: {'message': 'Invalid credentials'},
        ),
      );

      expect(failure.debugMessage, 'Invalid credentials');
    });

    test('les erreurs par champ sont extraites pour l’affichage inline', () {
      final failure = ErrorMapper.map(
        dioError(
          DioExceptionType.badResponse,
          statusCode: 422,
          data: {
            'message': 'Validation failed',
            'errors': {'email': 'Email is invalid'},
          },
        ),
      );

      expect(
        (failure as ValidationFailure).fieldErrors['email'],
        'Email is invalid',
      );
    });
  });

  group('charges utiles invalides', () {
    test('un JSON malformé est une erreur de validation, pas un réseau KO', () {
      // Un 200 au corps illisible ne doit pas déclencher le repli sur le
      // cache : la réponse est inexploitable, ce n'est pas une panne réseau.
      expect(
        ErrorMapper.map(const FormatException('bad json')),
        isA<ValidationFailure>(),
      );
    });

    test('un TypeError devient une erreur de validation', () {
      expect(ErrorMapper.map(TypeError()), isA<ValidationFailure>());
    });

    test('une exception inconnue reste inconnue', () {
      final failure = ErrorMapper.map(Exception('bruit de fond'));

      expect(failure, isA<UnknownFailure>());
      expect(failure.debugMessage, contains('Exception'));
    });
  });

  test('une ApiException est convertie sans être réencodée', () {
    const original = ApiException(UnauthorizedFailure(debugMessage: '401'));

    // La mapper ne re-typologie pas une failure déjà typée : elle conserve
    // son message de debug d'origine.
    final failure = ErrorMapper.map(original);

    expect(identical(failure, original.failure), isTrue);
    expect(failure.code, 'unauthorized');
  });
}
