/// Hiérarchie fermée des erreurs applicatives.
///
/// Toute erreur réseau, cache ou validation est convertie en [Failure] avant
/// d'atteindre la couche présentation. Le `code` permet à l'UI de choisir un
/// message localisé sans jamais afficher une exception brute à l'utilisateur.
sealed class Failure {
  const Failure();

  /// Identifiant technique stable, indépendant de la langue.
  String get code;

  /// Message technique destiné aux logs uniquement (jamais affiché tel quel).
  String get debugMessage;

  @override
  String toString() => '$runtimeType($code): $debugMessage';
}

/// Aucune connexion, DNS impossible, timeout réseau, etc.
final class NetworkFailure extends Failure {
  const NetworkFailure({this.debugMessage = 'Network unreachable'});

  @override
  final String debugMessage;

  @override
  String get code => 'network';
}

/// L'API a répondu avec un statut 5xx.
final class ServerFailure extends Failure {
  const ServerFailure({required this.statusCode, this.debugMessage = ''});

  final int statusCode;

  @override
  final String debugMessage;

  @override
  String get code => 'server';
}

/// Statut 401 / 403 : jeton absent, expiré ou refusé.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({this.debugMessage = 'Unauthorized'});

  @override
  final String debugMessage;

  @override
  String get code => 'unauthorized';
}

/// Statut 404.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({this.debugMessage = 'Not found'});

  @override
  final String debugMessage;

  @override
  String get code => 'not_found';
}

/// Le serveur a refusé la requête pour une raison métier (400, 409, 422...).
///
/// [fieldErrors] relie chaque champ du formulaire à son message serveur, ce qui
/// permet d'afficher l'erreur directement sous l'input concerné.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    this.debugMessage = 'Validation error',
    this.fieldErrors = const {},
  });

  @override
  final String debugMessage;
  final Map<String, String> fieldErrors;

  @override
  String get code => 'validation';
}

/// Le stockage local (Hive / secure storage) a échoué ou contenait des
/// données corrompues.
final class CacheFailure extends Failure {
  const CacheFailure({this.debugMessage = 'Cache error'});

  @override
  final String debugMessage;

  @override
  String get code => 'cache';
}

/// La requête a été annulée explicitement par l'appelant.
final class CancelledFailure extends Failure {
  const CancelledFailure({this.debugMessage = 'Request cancelled'});

  @override
  final String debugMessage;

  @override
  String get code => 'cancelled';
}

/// Filet de sécurité : aucune catégorie ne correspond.
final class UnknownFailure extends Failure {
  const UnknownFailure({this.debugMessage = 'Unknown error'});

  @override
  final String debugMessage;

  @override
  String get code => 'unknown';
}
