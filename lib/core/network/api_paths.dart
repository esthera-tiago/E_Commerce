/// Chemins de l'API REST.
///
/// Centraliser les URLs évite les chaînes magiques dispersées dans les data
/// sources et documente d'un coup d'œil le contrat serveur.
abstract final class ApiPaths {
  static const String auth = '/auth';
  static const String products = '/products';
  static const String users = '/users';
  static const String carts = '/carts';

  static String login() => '$auth/login';

  /// DummyJSON n'expose plus `POST /auth/signup` (404 une fois authentifié).
  /// La création de compte passe donc par `POST /users/add`, qui renvoie bien
  /// un utilisateur créé côté serveur. Voir `AuthRepositoryImpl.register`.
  static String register() => '$users/add';

  static String refresh() => '$auth/refresh';

  static String productsList({
    required int limit,
    required int skip,
    String? query,
    String? category,
  }) {
    return switch ((query, category)) {
      (final q?, _) when q.trim().isNotEmpty =>
        '$products/search?q=${Uri.encodeQueryComponent(q.trim())}&limit=$limit&skip=$skip',
      (_, final c?) when c.trim().isNotEmpty =>
        '$products/category/${Uri.encodeComponent(c.trim())}?limit=$limit&skip=$skip',
      _ => '$products?limit=$limit&skip=$skip',
    };
  }

  static String productById(int id) => '$products/$id';

  static String categories() => '$products/categories';

  static String cartsByUser(int userId) => '$carts/user/$userId';

  static String userById(int id) => '$users/$id';
}
