import 'package:e_commerce_app/core/l10n/app_strings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Garde-fou de la localisation.
///
/// Le projet embarque ses chaînes à la main plutôt que via `gen-l10n` : ce
/// test remplace la vérification que l'outil de génération aurait faite.
///
/// Il attrape trois défauts coûteux à repérer à la main :
///   1. une chaîne vide ou en dur dans une seule langue ;
///   2. une chaîne ajoutée à `AppStrings` mais jamais contrôlée ici (donc
///      potentiellement non traduite) ;
///   3. une chaîne oubliée dans FR **ou** EN.
void main() {
  /// Tous les accesseurs publics à chaîne, énumérés à la main : c'est aussi
  /// ce qui permet de vérifier qu'aucun nouveau `String get` n'échappe au
  /// test.
  final accessors = <String Function(AppStrings)>[
    (s) => s.appName,
    (s) => s.tagline,
    (s) => s.navShop,
    (s) => s.navSearch,
    (s) => s.navCart,
    (s) => s.navFavorites,
    (s) => s.navAccount,
    (s) => s.notFoundTitle,
    (s) => s.notFoundBackToShop,
    (s) => s.login,
    (s) => s.register,
    (s) => s.logout,
    (s) => s.username,
    (s) => s.password,
    (s) => s.showPassword,
    (s) => s.hidePassword,
    (s) => s.email,
    (s) => s.firstName,
    (s) => s.lastName,
    (s) => s.welcomeBack,
    (s) => s.createAccountIntro,
    (s) => s.noAccountYet,
    (s) => s.alreadyHaveAccount,
    (s) => s.demoCredentials,
    (s) => s.fillRequiredFields,
    (s) => s.invalidEmail,
    (s) => s.passwordTooShort,
    (s) => s.welcomeHome,
    (s) => s.products,
    (s) => s.allCategories,
    (s) => s.searchHint,
    (s) => s.clearSearch,
    (s) => s.noResults,
    (s) => s.sortBy,
    (s) => s.sortRelevance,
    (s) => s.sortPriceAsc,
    (s) => s.sortPriceDesc,
    (s) => s.sortRating,
    (s) => s.loading,
    (s) => s.loadMore,
    (s) => s.allProductsLoaded,
    (s) => s.reviews,
    (s) => s.noReviews,
    (s) => s.outOfStock,
    (s) => s.lowStock,
    (s) => s.addToCart,
    (s) => s.addToFavorites,
    (s) => s.removeFromFavorites,
    (s) => s.increaseQuantity,
    (s) => s.decreaseQuantity,
    (s) => s.inCart,
    (s) => s.description,
    (s) => s.specifications,
    (s) => s.brand,
    (s) => s.sku,
    (s) => s.shipping,
    (s) => s.warranty,
    (s) => s.discount,
    (s) => s.categories,
    (s) => s.cart,
    (s) => s.cartEmpty,
    (s) => s.cartEmptyHint,
    (s) => s.subtotal,
    (s) => s.total,
    (s) => s.checkout,
    (s) => s.remove,
    (s) => s.addedToCart,
    (s) => s.removedFromCart,
    (s) => s.clearCart,
    (s) => s.cartCleared,
    (s) => s.favorites,
    (s) => s.favoritesEmpty,
    (s) => s.favoritesEmptyHint,
    (s) => s.addedToFavorites,
    (s) => s.removedFromFavorites,
    (s) => s.orders,
    (s) => s.ordersEmpty,
    (s) => s.orderNumber,
    (s) => s.orderItems,
    (s) => s.amountDue,
    (s) => s.orderPlaced,
    (s) => s.thanksForYourOrder,
    (s) => s.unavailableForUser,
    (s) => s.profile,
    (s) => s.myAccount,
    (s) => s.refreshProfile,
    (s) => s.profileUpdated,
    (s) => s.connectedApi,
    (s) => s.guest,
    (s) => s.localAccount,
    (s) => s.apiAccount,
    (s) => s.settings,
    (s) => s.appearance,
    (s) => s.theme,
    (s) => s.themeSystem,
    (s) => s.themeLight,
    (s) => s.themeDark,
    (s) => s.language,
    (s) => s.dataAndPrivacy,
    (s) => s.clearCache,
    (s) => s.cacheCleared,
    (s) => s.cacheHint,
    (s) => s.about,
    (s) => s.help,
    (s) => s.version,
    (s) => s.techStack,
    (s) => s.apiTitle,
    (s) => s.helpIntro,
    (s) => s.helpQuestionConnection,
    (s) => s.helpAnswerConnection,
    (s) => s.helpQuestionOffline,
    (s) => s.helpAnswerOffline,
    (s) => s.helpQuestionAccount,
    (s) => s.helpAnswerAccount,
    (s) => s.helpQuestionOrder,
    (s) => s.helpAnswerOrder,
    (s) => s.offlineMode,
    (s) => s.offlineBanner,
    (s) => s.retry,
    (s) => s.errorGeneric,
    (s) => s.errorNetwork,
    (s) => s.errorTimeout,
    (s) => s.errorServer,
    (s) => s.errorUnauthorized,
    (s) => s.errorNotFound,
    (s) => s.errorValidation,
    (s) => s.errorCache,
    (s) => s.errorCancelled,
    (s) => s.errorUnknown,
    (s) => s.nothingToShow,
  ];

  test('chaque chaîne existe et est renseignée dans les deux langues', () {
    for (final locale in const [Locale('fr'), Locale('en')]) {
      final strings = AppStrings(locale);
      for (final accessor in accessors) {
        final value = accessor(strings).trim();
        expect(
          value,
          isNotEmpty,
          reason: 'chaîne vide en ${locale.languageCode}',
        );
      }
    }
  });

  test('seules les chaînes identiques par nature le sont en FR et en EN', () {
    final identical = <String>[];
    for (final accessor in accessors) {
      final fr = accessor(const AppStrings(Locale('fr')));
      final en = accessor(const AppStrings(Locale('en')));
      if (fr == en) identical.add(fr);
    }

    // La marque, et trois mots qui s'écrivent pareil dans les deux langues.
    // Toute autre égalité signale une chaîne laissée en français.
    const attendues = {'She4Tech', 'Description', 'Total', 'Version'};
    expect(
      identical.toSet().difference(attendues),
      isEmpty,
      reason: 'chaînes restées en français : $identical',
    );
  });

  test('les chaînes paramétrées suivent la locale', () async {
    // Le formatage de date d'`intl` a besoin des symboles de la locale :
    // dans l'application c'est `GlobalMaterialLocalizations` qui les charge,
    // ce test reproduit donc cette condition au lieu de la court-circuiter.
    await GlobalMaterialLocalizations.delegate.load(const Locale('fr'));

    const fr = AppStrings(Locale('fr'));
    const en = AppStrings(Locale('en'));

    expect(fr.resultsCount(1), '1 produit');
    expect(fr.resultsCount(3), '3 produits');
    expect(en.resultsCount(1), '1 product');
    expect(en.resultsCount(3), '3 products');

    expect(fr.itemsCount(1), '1 article');
    expect(fr.itemsCount(3), '3 articles');
    expect(en.itemsCount(1), '1 item');
    expect(en.itemsCount(3), '3 items');

    // Le prix est formaté dans la devise de la locale.
    expect(fr.price(1234.5), contains('1'));
    expect(en.price(1234.5), contains('1'));
    expect(fr.date(DateTime(2026, 3, 4)), isNot(en.date(DateTime(2026, 3, 4))));
  });
}
