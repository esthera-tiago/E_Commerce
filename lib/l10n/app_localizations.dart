import 'package:flutter/material.dart';

import '../widgets/app_scope.dart';

class AppLocalizations {
  const AppLocalizations._(this._lang);
  final String _lang;

  static AppLocalizations of(BuildContext context) {
    final locale = AppScope.of(context).locale;
    return AppLocalizations._(locale.languageCode);
  }

  bool get _fr => _lang == 'fr';

  // --- Navigation ---
  String get boutique => _fr ? 'Boutique' : 'Shop';
  String get panier => _fr ? 'Panier' : 'Cart';
  String get favoris => _fr ? 'Favoris' : 'Favorites';
  String get profil => _fr ? 'Profil' : 'Profile';

  // --- Product ---
  String get rechercher => _fr ? 'Rechercher...' : 'Search...';
  String get tout => _fr ? 'Tout' : 'All';
  String get recents => _fr ? 'Recents' : 'Newest';
  String get prixCroissant => _fr ? 'Prix croissant' : 'Price ascending';
  String get prixDecroissant => _fr ? 'Prix decroissant' : 'Price descending';
  String get meilleuresNotes => _fr ? 'Meilleures notes' : 'Top rated';
  String get avis => _fr ? 'avis' : 'reviews';
  String get ajouterAuPanier => _fr ? 'Ajouter au panier' : 'Add to cart';
  String articleAjoute(String name) =>
      _fr ? '$name ajoute au panier' : '$name added to cart';
  String articleRetire(String name) =>
      _fr ? '$name retire du panier' : '$name removed from cart';
  String get votreNote => _fr ? 'Votre note' : 'Your rating';
  String noteEnregistree(int n) =>
      _fr ? 'Note de $n etoile(s) enregistree' : '$n star rating saved';
  String get aucunProduit => _fr ? 'Aucun produit trouve.' : 'No products found.';

  // --- Favorites ---
  String get aucunFavori => _fr
      ? 'Aucun favori pour le moment.'
      : 'No favorites yet.';

  // --- Cart ---
  String get panierVide => _fr ? 'Votre panier est vide.' : 'Your cart is empty.';
  String get total => _fr ? 'Total' : 'Total';
  String get commander => _fr ? 'Commander' : 'Checkout';
  String get commandePassee => _fr
      ? 'Commande passee (simulation)'
      : 'Order placed (simulation)';

  // --- Profile ---
  String get appuyezModifier => _fr
      ? 'Appuyez pour modifier'
      : 'Tap to edit';
  String get modifierProfil => _fr ? 'Modifier le profil' : 'Edit profile';
  String get nom => _fr ? 'Nom' : 'Name';
  String get email => _fr ? 'Email' : 'Email';
  String get enregistrer => _fr ? 'Enregistrer' : 'Save';
  String get profilMisAJour => _fr ? 'Profil mis a jour' : 'Profile updated';
  String get choisirAvatar => _fr ? 'Choisir un avatar' : 'Choose an avatar';
  String get membreDepuis => _fr ? 'Membre depuis' : 'Member since';
  String get pointsFidelite => _fr ? 'Points fidelite' : 'Loyalty points';

  // --- Settings ---
  String get parametres => _fr ? 'Parametres' : 'Settings';
  String get apparence => _fr ? 'Apparence' : 'Appearance';
  String get modeSombre => _fr ? 'Mode sombre' : 'Dark mode';
  String get activerThemeSombre => _fr
      ? 'Activer le theme sombre'
      : 'Enable dark theme';
  String get langue => _fr ? 'Langue' : 'Language';
  String get langueApp => _fr
      ? 'Langue de l\'application'
      : 'Application language';
  String get notifications => _fr ? 'Notifications' : 'Notifications';
  String get notificationsPush => _fr ? 'Notifications push' : 'Push notifications';
  String get recevoirAlertes => _fr
      ? 'Recevoir les alertes promotionnelles'
      : 'Receive promotional alerts';
  String get alertesEmail => _fr ? 'Alertes email' : 'Email alerts';
  String get nouvellesOffres => _fr
      ? 'Nouvelles offres et commandes'
      : 'New offers and orders';
  String get confidentialite => _fr ? 'Confidentialite' : 'Privacy';
  String get politiqueConfidentialite => _fr
      ? 'Politique de confidentialite'
      : 'Privacy policy';
  String get supprimerDonnees => _fr
      ? 'Supprimer mes donnees'
      : 'Delete my data';
  String get effacerDonnees => _fr
      ? 'Effacer toutes les donnees locales'
      : 'Erase all local data';
  String get confirmerSuppression => _fr
      ? 'Confirmer la suppression'
      : 'Confirm deletion';
  String get texteSuppression => _fr
      ? 'Toutes vos donnees locales seront effacees. Cette action est irreversible.'
      : 'All your local data will be erased. This action is irreversible.';
  String get annuler => _fr ? 'Annuler' : 'Cancel';
  String get supprimer => _fr ? 'Supprimer' : 'Delete';

  // --- Help ---
  String get aideContact => _fr ? 'Aide & contact' : 'Help & contact';
  String get questionsFrequentes => _fr
      ? 'Questions frequentes'
      : 'Frequently asked questions';
  String get faqPanier => _fr
      ? 'Comment ajouter un article au panier ?'
      : 'How to add an item to the cart?';
  String get faqPanierRep => _fr
      ? 'Appuyez sur l\'icone panier sur la carte du produit, ou ouvrez la fiche produit et cliquez sur "Ajouter au panier".'
      : 'Tap the cart icon on the product card, or open the product page and tap "Add to cart".';
  String get faqFavori => _fr
      ? 'Comment ajouter un favori ?'
      : 'How to add a favorite?';
  String get faqFavoriRep => _fr
      ? 'Appuyez sur l\'icone coeur sur la carte du produit ou dans la fiche produit. Vos favoris sont sauvegardes localement.'
      : 'Tap the heart icon on the product card or product page. Your favorites are saved locally.';
  String get faqNotation => _fr
      ? 'Comment noter un produit ?'
      : 'How to rate a product?';
  String get faqNotationRep => _fr
      ? 'Ouvrez la fiche du produit et utilisez les etoiles dans la section "Votre note". Votre note est sauvegardee.'
      : 'Open the product page and use the stars in the "Your rating" section. Your rating is saved.';
  String get faqRecherche => _fr
      ? 'Comment rechercher un produit ?'
      : 'How to search for a product?';
  String get faqRechercheRep => _fr
      ? 'Utilisez la barre de recherche en haut de la page Boutique. Vous pouvez aussi filtrer par categorie et trier par prix ou note.'
      : 'Use the search bar at the top of the Shop page. You can also filter by category and sort by price or rating.';
  String get nousContacter => _fr ? 'Nous contacter' : 'Contact us';
  String get messageEnvoye => _fr ? 'Message envoye !' : 'Message sent!';
  String get reponseBrefsDelais => _fr
      ? 'Nous vous repondrons dans les plus brefs delais.'
      : 'We will get back to you as soon as possible.';
  String get saisirNom => _fr
      ? 'Veuillez saisir votre nom'
      : 'Please enter your name';
  String get saisirEmail => _fr
      ? 'Veuillez saisir votre email'
      : 'Please enter your email';
  String get emailInvalide => _fr ? 'Email invalide' : 'Invalid email';
  String get saisirMessage => _fr
      ? 'Veuillez saisir votre message'
      : 'Please enter your message';
  String get envoyer => _fr ? 'Envoyer' : 'Send';

  // --- About ---
  String get aPropos => _fr ? 'A propos' : 'About';
  String get version => _fr ? 'Version 1.0.0' : 'Version 1.0.0';
  String get aProposApp => _fr
      ? 'A propos de l\'application'
      : 'About the application';
  String get descriptionApp => _fr
      ? 'She4Tech Boutique est une application e-commerce premium developpee avec Flutter et Riverpod. Elle propose une experience d\'achat fluide avec catalogue, panier, favoris et notation des produits.'
      : 'She4Tech Boutique is a premium e-commerce app built with Flutter and Riverpod. It offers a smooth shopping experience with catalogue, cart, favorites, and product ratings.';
  String get technologies => _fr ? 'Technologies' : 'Technologies';
  String get licence => _fr ? 'Licence' : 'License';
  String get licenceTexte => _fr
      ? 'Application developpee dans le cadre du projet Multi-Screen de She4Tech. Tous droits reserves.'
      : 'Application developed as part of the She4Tech Multi-Screen project. All rights reserved.';
  String get framework => 'Framework';
  String get etat => _fr ? 'Etat' : 'State';
  String get navigation => 'Navigation';
  String get persistance => _fr ? 'Persistance' : 'Persistence';
  String get images => 'Images';

  // --- General ---
  String get erreurChargement => _fr ? 'Erreur de chargement:' : 'Loading error:';
  String get erreur => _fr ? 'Erreur:' : 'Error:';
  String get fermer => _fr ? 'Fermer' : 'Close';
}
