import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Réponses HTTP servies en mémoire, indexées par fragment d'URL.
///
/// Permet de tester l'application entière (routeur, repositories, DTO) sans
/// réseau ni latence, avec des charges utiles conformes à l'API réelle.
class FakeApi {
  final Map<String, Object Function(Map<String, dynamic> query)> _routes = {};
  final List<String> requests = [];

  /// Bascule le faux réseau en panne totale.
  ///
  /// Le catalogue ne se rabat sur son cache que sur une panne *réseau* : un 500
  /// ou un 404 doivent rester de vraies erreurs. Reproduire la coupure exige
  /// donc une exception de connexion, pas un statut HTTP.
  bool offline = false;

  /// Enregistre une réponse pour toute URL contenant [fragment].
  void on(
    String fragment,
    Object Function(Map<String, dynamic> query) handler,
  ) {
    _routes[fragment] = handler;
  }

  /// Charge utile dynamique : permet de reproduire un 500 ou un 401.
  void onStatus(String fragment, int statusCode, Object? body) {
    _routes[fragment] = (query) => _Status(statusCode, body);
  }

  /// Nombre d'appels effectués sur une route.
  int hits(String fragment) =>
      requests.where((r) => r.contains(fragment)).length;

  Dio dio() => Dio()..httpClientAdapter = _FakeAdapter(this);
}

class _Status {
  const _Status(this.code, this.body);
  final int code;
  final Object? body;
}

/// Adaptateur Dio branché sur [FakeApi] : aucune socket n'est ouverte.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.api);

  final FakeApi api;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final query = options.uri.queryParameters;
    api.requests.add('${options.method} ${options.uri.path}');

    if (api.offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'Réseau indisponible',
      );
    }

    Object? payload;
    var status = 200;
    var matched = false;
    for (final entry in api._routes.entries) {
      if (options.uri.toString().contains(entry.key)) {
        final result = entry.value(query);
        if (result is _Status) {
          status = result.code;
          payload = result.body;
        } else {
          payload = result;
        }
        matched = true;
        break;
      }
    }

    // Une route inconnue renvoie un 404 explicite, pour qu'une oubli dans le
    // test se lise comme telle et non comme une panne réseau.
    if (!matched) {
      status = 404;
      payload = {'message': 'no fake route for ${options.uri.path}'};
    }

    return ResponseBody.fromString(
      jsonEncode(payload),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
