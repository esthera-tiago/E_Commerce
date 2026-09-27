/// Configuration applicative.
///
/// Les valeurs sensibles sont injectées à la compilation via
/// `--dart-define` (voir README), avec une valeur par défaut qui fonctionne
/// immédiatement pour une démonstration. L'application reste donc exécutable
/// sans aucun fichier de configuration secret.
abstract final class AppConfig {
  /// URL de base de l'API REST publique.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dummyjson.com',
  );

  /// Durée maximale d'une requête réseau.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Délai d'attente de la première octet de réponse.
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Nombre de produits chargés par page dans le catalogue.
  static const int catalogPageSize = 20;

  /// Durée de vie du cache local avant d'être considéré comme périmé.
  static const Duration cacheTtl = Duration(days: 7);

  /// Identifiants de démonstration fournis par l'API, affichés sur l'écran
  /// de connexion pour faciliter la prise en main.
  ///
  /// Vérifié en ligne : `emilys` / `emilyspass` renvoie bien un couple de
  /// jetons JWT. Le compte `emilyj` existe mais son mot de passe est
  /// `emilyjpass` — l'apporter ici ferait échouer la connexion.
  static const String demoUsername = 'emilys';
  static const String demoPassword = 'emilyspass';
}
