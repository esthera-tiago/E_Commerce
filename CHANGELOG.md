# Changelog

Ce fichier suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le
versionnement sémantique. Les versions ci-dessous correspondent aux lots de
commits réellement mergés dans `main`.

## [Non publié]

Travail en cours sur la branche courante.

## [2.1.0] — 2026-09-28

### Ajouté
- Accessibilité : `Semantics` sur les éléments interactifs, libellé de
  chargement annoncé sur les 8 indicateurs de progression, en-têtes de section
  marqués comme tels.
- Les tuiles du catalogue sont annoncées par ce qu'elles décrivent — marque,
  titre, note, remise, prix, quantité au panier — au lieu d'être une mosaïque
  de textes sans lien, le bouton favori restant une cible séparée.
- Une note produit est annoncée comme une note unique (« Note : 4,5 sur 5 »)
  et non comme cinq étoiles distinctes.
- `AppStrings.rating()` et un `semanticLabel` sur `RemoteImage` : la fiche
  produit nomme son image, les vignettes de catalogue restent muettes.
- 5 tests d'accessibilité qui parcourent l'arbre de sémantique réel des quatre
  onglets, de la fiche produit et de la connexion ; la suite échoue si un nœud
  actionnable reste sans nom.
- 3 tests de garde-fous i18n : les 130 chaînes FR/EN non vides, l'absence de
  doublon entre les deux langues, et le bon fonctionnement des chaînes
  paramétrées.
- 2 tests mesurant les reconstructions réelles de la grille : un favori ou un
  ajout au panier ne doit réveiller que la tuile concernée.
- 4 tests de parcours : achat complet jusqu'au panier vidé, survie du panier à
  un redémarrage, catalogue lisible hors-ligne, et refus d'inventer un
  catalogue sans réseau ni cache.
- Décodage des images à la taille d'affichage (`memCacheWidth`, plafonné à
  2048 px physiques) au lieu de la pleine résolution de la source.
- `RepaintBoundary` sur chaque tuile du catalogue.
- Budget mémoire d'images explicite (96 Mo) au lieu du défaut Flutter.
- `CHANGELOG.md`, workflows GitHub Actions (qualité + build web, APK debug
  manuel ou sur tag) et badges correspondants dans le README.
- Tests réorganisés en `test/unit`, `test/widget` et `test/integration`.

### Corrigé
- La page 404 était codée en dur en français et s'affichait donc en français à
  un utilisateur anglophone ; elle est désormais localisée.
- Les indicateurs de progression n'étaient pas annoncés aux lecteurs d'écran.
- Chaque tuile observait l'état complet du panier : un seul ajout reconstruisait
  les vingt cellules de la grille. Elle n'observe plus que sa propre quantité.
- L'abonnement à `connectivity_plus` n'était jamais annulé : chaque
  recréation du provider laissait un abonné orphelin sur le canal, et le
  bandeau « hors-ligne » restait figé sur son dernier état connu.

## [2.0.0] — 2026-09-27

### Ajouté
- API REST réelle : [DummyJSON](https://dummyjson.com) remplace les données de
  démonstration locales (8 points d'entrée).
- Clean Architecture par fonctionnalité (`data` / `domain` / `presentation`) et
  socle transversal `core` ; l'ancien découpage `screens` / `models` /
  `providers` disparaît.
- `GoRouter` avec garde de session et quatre onglets conservant leur propre
  pile de navigation (`StatefulShellRoute.indexedStack`).
- Cache hors-ligne Hive horodaté, cloisonné par utilisateur, avec remplacement
  atomique et lecture au démarrage.
- `flutter_secure_storage` pour les seuls JWT : aucun secret n'atteint Hive.
- Intercepteur Dio qui rafraîchit le jeton sur `401` et rejoue la requête en
  sérialisant les rafraîchissements concurrents.
- 76 tests sans réseau : adaptateur Dio en mémoire, doubles de stockage, suite
  de bout en bout et suite de captures d'écran.
- README réécrit (architecture, persistance, API, tests, limites connues).

### Corrigé
- Les délégués `MaterialLocalizations` / `CupertinoLocalizations` manquaient :
  l'interface française levait une exception à l'exécution.
- `connectivity_plus` sans implémentation levait une `MissingPluginException` non
  gérée ; le flux est désormais protégé et retombe sur « en ligne ».
- Débordements de mise en page en français sur un écran de 390 pt : grille
  catalogue, prix des cartes produit, prix du détail produit, en-tête de
  commande, pied de page de connexion.
- Les entrées de panier dont le produit n'est pas un objet JSON sont ignorées
  au lieu de casser l'écran.
- `GlobalMaterialLocalizations` / `GlobalCupertinoLocalizations` enregistrés
  auprès du routeur.

### Supprimé
- `assets/data/products.json` et le repository associé.

## [1.0.0] — 2026-08-16

### Ajouté
- Catalogue avec recherche, catégories et tri.
- Fiche produit avec note, avis, livraison, garantie et retour.
- Panier persistant, favoris, historique de commandes et profil éditable.
- Réglages : thème clair/sombre, choix de la langue, notifications,
  confidentialité.
- Internationalisation complète FR/EN.
- Photos produits via `cached_network_image` et écrans d'aide / à propos.
- Badge de quantité sur l'icône panier.

### Corrigé
- `ProductCard` sans contrainte de hauteur sur l'écran des favoris.

## [0.1.0] — 2026-08-16

### Ajouté
- Première version de l'application e-commerce : état global Riverpod,
  écrans de connexion, catalogue et fiche produit, données produit en lecture
  depuis un fichier JSON local.

[Non publié]: https://github.com/esthera-tiago/E_Commerce/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/esthera-tiago/E_Commerce/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/esthera-tiago/E_Commerce/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/esthera-tiago/E_Commerce/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/esthera-tiago/E_Commerce/releases/tag/v0.1.0
