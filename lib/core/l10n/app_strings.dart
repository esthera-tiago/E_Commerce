import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../error/failure.dart';

/// Localisation FR / EN de l'application.
///
/// Implémentation manuelle (sans `gen-l10n`) : les deux jeux de chaînes
/// restent dans un seul fichier lisible, ce qui facilite la relecture en
/// localisation et évite une étape de génération dans le pipeline CI.
class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('fr'), Locale('en')];

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings(Locale('fr'));

  bool get isFrench => locale.languageCode == 'fr';

  String _pick(String fr, String en) => isFrench ? fr : en;

  /// Formate un prix en unités de la locale courante.
  String price(double value) =>
      NumberFormat.simpleCurrency(locale: locale.toString()).format(value);

  String date(DateTime value) =>
      DateFormat.yMMMd(locale.toString()).format(value);

  /// Note sur 5, annoncée aux lecteurs d'écran à la place des cinq étoiles.
  String rating(double value) {
    final formatted = NumberFormat('#,##0.0', locale.toString()).format(value);
    return _pick('Note $formatted sur 5', 'Rating $formatted out of 5');
  }

  // ----------------------------------------------------------------- app ---
  String get appName => _pick('She4Tech', 'She4Tech');
  String get tagline => _pick('Boutique connectée', 'Connected store');

  // -------------------------------------------------------- navigation ---
  String get navShop => _pick('Boutique', 'Shop');
  String get navSearch => _pick('Recherche', 'Search');
  String get navCart => _pick('Panier', 'Cart');
  String get navFavorites => _pick('Favoris', 'Favorites');
  String get navAccount => _pick('Compte', 'Account');

  // --------------------------------------------------------- page 404 ---
  String get notFoundTitle => _pick('Page introuvable', 'Page not found');
  String get notFoundBackToShop =>
      _pick('Retour à la boutique', 'Back to the store');

  // -------------------------------------------------------------- auth ---
  String get login => _pick('Connexion', 'Sign in');
  String get register => _pick('Créer un compte', 'Create account');
  String get logout => _pick('Se déconnecter', 'Sign out');
  String get username => _pick('Nom d’utilisateur', 'Username');
  String get password => _pick('Mot de passe', 'Password');
  String get showPassword => _pick('Afficher le mot de passe', 'Show password');
  String get hidePassword => _pick('Masquer le mot de passe', 'Hide password');
  String get email => _pick('Adresse e-mail', 'Email address');
  String get firstName => _pick('Prénom', 'First name');
  String get lastName => _pick('Nom', 'Last name');
  String get welcomeBack => _pick('Ravi de vous revoir', 'Welcome back');
  String get createAccountIntro => _pick(
    'Créez votre compte en quelques secondes.',
    'Create your account in seconds.',
  );
  String get noAccountYet => _pick('Pas encore de compte ?', 'No account yet?');
  String get alreadyHaveAccount =>
      _pick('Vous avez déjà un compte ?', 'Already have an account?');
  String get demoCredentials => _pick(
    'Identifiants de démo : emilys / emilyspass',
    'Demo credentials: emilys / emilyspass',
  );
  String get fillRequiredFields => _pick(
    'Tous les champs marqués * sont obligatoires.',
    'All fields marked * are required.',
  );
  String get invalidEmail =>
      _pick('Adresse e-mail invalide.', 'Invalid email address.');
  String get passwordTooShort => _pick(
    'Le mot de passe doit contenir au moins 6 caractères.',
    'Password must be at least 6 characters.',
  );
  String get welcomeHome => _pick('Bonjour', 'Hello');

  // ---------------------------------------------------------- catalogue ---
  String get products => _pick('Produits', 'Products');
  String get allCategories => _pick('Toutes les catégories', 'All categories');
  String get searchHint => _pick('Rechercher un produit…', 'Search a product…');
  String get clearSearch => _pick('Effacer la recherche', 'Clear search');
  String get noResults => _pick('Aucun produit trouvé.', 'No product found.');
  String get sortBy => _pick('Trier par', 'Sort by');
  String get sortRelevance => _pick('Pertinence', 'Relevance');
  String get sortPriceAsc => _pick('Prix croissant', 'Price: low to high');
  String get sortPriceDesc => _pick('Prix décroissant', 'Price: high to low');
  String get sortRating => _pick('Mieux notés', 'Top rated');
  String resultsCount(int count) => isFrench
      ? (count == 1 ? '1 produit' : '$count produits')
      : (count == 1 ? '1 product' : '$count products');
  String get loading => _pick('Chargement…', 'Loading…');
  String get loadMore => _pick('Charger plus', 'Load more');
  String get allProductsLoaded =>
      _pick('Vous avez tout vu', 'You have reached the end');
  String get reviews => _pick('Avis clients', 'Customer reviews');
  String get noReviews =>
      _pick('Aucun avis pour ce produit.', 'No reviews for this product.');
  String get outOfStock => _pick('Rupture de stock', 'Out of stock');
  String get lowStock => _pick('Stock faible', 'Low stock');
  String get addToCart => _pick('Ajouter au panier', 'Add to cart');
  String get addToFavorites => _pick('Ajouter aux favoris', 'Add to favorites');
  String get removeFromFavorites =>
      _pick('Retirer des favoris', 'Remove from favorites');
  String get increaseQuantity =>
      _pick('Augmenter la quantité', 'Increase quantity');
  String get decreaseQuantity =>
      _pick('Diminuer la quantité', 'Decrease quantity');
  String get inCart => _pick('Dans le panier', 'In cart');
  String get description => _pick('Description', 'Description');
  String get specifications => _pick('Caractéristiques', 'Specifications');
  String get brand => _pick('Marque', 'Brand');
  String get sku => _pick('Référence', 'SKU');
  String get shipping => _pick('Livraison', 'Shipping');
  String get warranty => _pick('Garantie', 'Warranty');
  String get discount => _pick('Remise', 'Discount');
  String get categories => _pick('Catégories', 'Categories');

  // ------------------------------------------------------------ panier ---
  String get cart => _pick('Panier', 'Cart');
  String get cartEmpty =>
      _pick('Votre panier est vide.', 'Your cart is empty.');
  String get cartEmptyHint => _pick(
    'Parcourez la boutique pour ajouter des articles.',
    'Browse the store to add items.',
  );
  String get subtotal => _pick('Sous-total', 'Subtotal');
  String get total => _pick('Total', 'Total');
  String get checkout => _pick('Commander', 'Checkout');
  String get remove => _pick('Retirer', 'Remove');
  String itemsCount(int count) => isFrench
      ? (count == 1 ? '1 article' : '$count articles')
      : (count == 1 ? '1 item' : '$count items');
  String get addedToCart => _pick('Ajouté au panier', 'Added to cart');
  String get removedFromCart => _pick('Retiré du panier', 'Removed from cart');
  String get clearCart => _pick('Vider le panier', 'Clear cart');
  String get cartCleared => _pick('Panier vidé', 'Cart cleared');

  // ---------------------------------------------------------- favoris ---
  String get favorites => _pick('Favoris', 'Favorites');
  String get favoritesEmpty =>
      _pick('Aucun favori pour l’instant.', 'No favorites yet.');
  String get favoritesEmptyHint => _pick(
    'Touchez le cœur d’un produit pour le retrouver ici.',
    'Tap a product heart to find it here.',
  );
  String get addedToFavorites =>
      _pick('Ajouté aux favoris', 'Added to favorites');
  String get removedFromFavorites =>
      _pick('Retiré des favoris', 'Removed from favorites');

  // --------------------------------------------------------- commandes ---
  String get orders => _pick('Commandes', 'Orders');
  String get ordersEmpty => _pick('Aucune commande.', 'No orders yet.');
  String get orderNumber => _pick('Commande', 'Order');
  String get orderItems => _pick('articles', 'items');
  String get amountDue => _pick('Montant dû', 'Amount due');
  String get orderPlaced => _pick('Commande confirmée', 'Order confirmed');
  String get thanksForYourOrder =>
      _pick('Merci pour votre commande !', 'Thanks for your order!');
  String get unavailableForUser => _pick(
    'Aucune commande en ligne pour ce compte.',
    'No online orders for this account.',
  );

  // ------------------------------------------------------------ profil ---
  String get profile => _pick('Profil', 'Profile');
  String get myAccount => _pick('Mon compte', 'My account');
  String get refreshProfile => _pick('Actualiser le profil', 'Refresh profile');
  String get profileUpdated => _pick('Profil à jour', 'Profile up to date');
  String get connectedApi =>
      _pick('Données fournies par l’API REST', 'Data served by the REST API');
  String get guest => _pick('Visiteur', 'Guest');
  String get localAccount =>
      _pick('Compte créé sur cet appareil', 'Account created on this device');
  String get apiAccount =>
      _pick('Compte fourni par l’API', 'Account served by the API');

  // ---------------------------------------------------------- réglages ---
  String get settings => _pick('Réglages', 'Settings');
  String get appearance => _pick('Apparence', 'Appearance');
  String get theme => _pick('Thème', 'Theme');
  String get themeSystem => _pick('Système', 'System');
  String get themeLight => _pick('Clair', 'Light');
  String get themeDark => _pick('Sombre', 'Dark');
  String get language => _pick('Langue', 'Language');
  String get dataAndPrivacy =>
      _pick('Données et confidentialité', 'Data and privacy');
  String get clearCache => _pick('Vider le cache local', 'Clear local cache');
  String get cacheCleared => _pick('Cache local vidé', 'Local cache cleared');
  String get cacheHint => _pick(
    'Supprime les produits, commandes et fiches enregistrés sur l’appareil.',
    'Deletes products, orders and profiles stored on this device.',
  );
  String get about => _pick('À propos', 'About');
  String get help => _pick('Aide', 'Help');
  String get version => _pick('Version', 'Version');
  String get techStack => _pick('Pile technique', 'Tech stack');
  String get apiTitle => _pick('API REST', 'REST API');
  String get helpIntro => _pick(
    'Une question ? Consultez les réponses ci-dessous ou testez les identifiants de démo.',
    'Got a question? Check the answers below or try the demo credentials.',
  );
  String get helpQuestionConnection => _pick(
    'Pourquoi certains produits ne se chargent-ils pas ?',
    'Why do some products fail to load?',
  );
  String get helpAnswerConnection => _pick(
    'L’API DummyJSON est publique et peut être lente ou indisponible par moments. '
        'Réessayez, ou activez le mode hors-ligne pour consulter les produits déjà enregistrés.',
    'The public DummyJSON API can be slow or temporarily unavailable. '
        'Retry, or switch to offline mode to browse products already stored on this device.',
  );
  String get helpQuestionOffline => _pick(
    'Comment fonctionne le mode hors-ligne ?',
    'How does offline mode work?',
  );
  String get helpAnswerOffline => _pick(
    'Catalogue, fiches produit, commandes et favoris sont mis en cache localement à chaque '
        'visite. Le panier reste toujours sur l’appareil et fonctionne sans connexion.',
    'Catalog, product details, orders and favorites are cached locally on every visit. '
        'Your cart always lives on this device and works without a connection.',
  );
  String get helpQuestionAccount => _pick(
    'Puis-je créer un compte depuis l’application ?',
    'Can I create an account in the app?',
  );
  String get helpAnswerAccount => _pick(
    'Oui, mais l’API de démonstration ne permet pas de se connecter avec un compte créé '
        'par l’application : ces identifiants sont enregistrés sur cet appareil uniquement. '
        'Pour tester la connexion serveur, utilisez emilys / emilyspass.',
    'Yes, but the demo API does not allow signing in with an app-created account: those '
        'credentials stay on this device only. To test the server sign-in, use emilys / emilyspass.',
  );
  String get helpQuestionOrder =>
      _pick('Où sont mes commandes ?', 'Where are my orders?');
  String get helpAnswerOrder => _pick(
    'L’historique affiché vient de l’API : il correspond aux paniers enregistrés par le compte '
        'de démonstration. Le panier de l’application est, lui, purely local.',
    'The history shown comes from the API and matches the carts recorded for the demo '
        'account. The in-app cart itself is purely local.',
  );

  // ------------------------------------------------------------- états ---
  String get offlineMode => _pick('Mode hors-ligne', 'Offline mode');
  String get offlineBanner => _pick(
    'Hors-ligne — affichage des données en cache',
    'Offline — showing cached data',
  );
  String get retry => _pick('Réessayer', 'Retry');
  String get errorGeneric =>
      _pick('Une erreur est survenue.', 'Something went wrong.');
  String get errorNetwork => _pick(
    'Connexion impossible. Vérifiez votre réseau.',
    'Network unreachable. Check your connection.',
  );
  String get errorTimeout => _pick(
    'Le serveur met trop de temps à répondre.',
    'The server is taking too long to respond.',
  );
  String get errorServer => _pick(
    'Le serveur a rencontré un problème.',
    'The server ran into a problem.',
  );
  String get errorUnauthorized => _pick(
    'Session expirée, veuillez vous reconnecter.',
    'Session expired, please sign in again.',
  );
  String get errorNotFound => _pick('Introuvable.', 'Not found.');
  String get errorValidation => _pick('Données invalides.', 'Invalid data.');
  String get errorCache => _pick(
    'Impossible d’accéder au cache local.',
    'Local cache is unavailable.',
  );
  String get errorCancelled => _pick('Requête annulée.', 'Request cancelled.');
  String get errorUnknown => _pick('Erreur inconnue.', 'Unknown error.');
  String get nothingToShow => _pick('Rien à afficher', 'Nothing to show');

  /// Traduit une [Failure] métier en message affichable.
  ///
  /// Point de contact unique entre la couche d'erreur et l'UI : aucune vue ne
  /// manipule directement les types d'exception.
  String failure(Failure failure) => switch (failure) {
    NetworkFailure() => errorNetwork,
    ServerFailure() => errorServer,
    UnauthorizedFailure() => errorUnauthorized,
    NotFoundFailure() => errorNotFound,
    ValidationFailure() => errorValidation,
    CacheFailure() => errorCache,
    CancelledFailure() => errorCancelled,
    UnknownFailure() => errorUnknown,
  };

  String apiExceptionMessage(String message) {
    final exception = _pick('Erreur de l’API', 'API error');
    return '$exception : $message';
  }
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => AppStrings.supportedLocales.any(
    (l) => l.languageCode == locale.languageCode,
  );

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
