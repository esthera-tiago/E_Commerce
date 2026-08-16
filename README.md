# E-Commerce App — Boutique

Application e-commerce Flutter premium alimentee par **Riverpod** pour la gestion d'etat.

## Architecture

```
lib/
  main.dart                          # Point d'entree, ProviderScope
  app.dart                           # MaterialApp.router + theme toggle
  router/
    app_router.dart                  # GoRouter — 8 routes
  theme/
    app_theme.dart                   # Material 3 light + dark (seed #1A1A2E)
  models/
    product.dart                     # Product (immutable, copyWith, fromJson)
    cart_item.dart                   # CartItem (Product + quantity)
    user.dart                        # User (mock profile)
    filter_state.dart                # FilterState + SortOption enum
  data/
    products.json                    # 20 produits reels (Lorem Picsum)
    product_repository.dart          # Chargement asset + cache memoire
  providers/
    product_provider.dart            # productList, categories, filter, filteredProducts
    cart_provider.dart               # cart (StateNotifier), cartTotal, cartItemCount
    favorites_provider.dart          # sharedPrefs, favorites (persiste localement)
    user_provider.dart               # user (mock)
    user_ratings_provider.dart       # userRatings (persiste SharedPreferences)
  screens/
    home_screen.dart                 # Catalogue (grille, recherche, filtres)
    product_detail_screen.dart       # Detail produit + notation etoiles
    cart_screen.dart                 # Panier + commande
    favorites_screen.dart            # Favoris
    profile_screen.dart              # Profil + navigation vers sous-ecrans
    settings_screen.dart             # Parametres (theme, notifications, vie privee)
    help_screen.dart                 # Aide FAQ + formulaire de contact
    about_screen.dart                # A propos de l'application
  widgets/
    adaptive_scaffold.dart           # Responsive (NavigationRail / BottomBar)
    filter_bar.dart                  # Recherche + chips categorie + tri
    product_card.dart                # Carte produit avec favori + panier + image reseau
    animated_cart_button.dart        # Bouton avec animation scale
    cart_item_tile.dart              # Ligne panier avec +/- et image thumbnail
    rating_bar.dart                  # Barre d'etoiles interactive (1 a 5)
    app_scope.dart                   # InheritedWidget pour theme toggle
```

## Providers (11 au total)

| Provider | Type | Role |
|---|---|---|
| `productRepositoryProvider` | `Provider<ProductRepository>` | Singleton repository |
| `productListProvider` | `FutureProvider<List<Product>>` | Produits depuis JSON |
| `categoriesProvider` | `FutureProvider<List<String>>` | Categories dynamiques |
| `filterProvider` | `StateNotifierProvider<FilterNotifier, FilterState>` | Filtres + tri |
| `filteredProductsProvider` | `Provider<List<Product>>` | Produits filtres (derive) |
| `cartProvider` | `StateNotifierProvider<CartNotifier, List<CartItem>>` | Panier |
| `cartItemCountProvider` | `Provider<int>` | Nombre total d'articles |
| `cartTotalProvider` | `Provider<double>` | Montant total |
| `sharedPrefsProvider` | `FutureProvider<SharedPreferences>` | Persistance |
| `favoritesProvider` | `StateNotifierProvider<FavoritesNotifier, Set<String>>` | Favoris persistes |
| `userRatingsProvider` | `StateNotifierProvider<UserRatingsNotifier, Map<String, int>>` | Notation persistee |
| `userProvider` | `Provider<User>` | Profil mock |

## Fonctionnalites

- Catalogue avec grille responsive et cartes produit (images reelles Lorem Picsum)
- Detail produit avec notation etoiles (1-5, persistee localement)
- Panier : ajout, suppression, modification de quantite, total dynamique
- Favoris : toggle persiste via SharedPreferences
- Recherche textuelle, filtrage par categorie, tri (prix, note, recents)
- Profil avec navigation vers Parametres, Aide, A propos
- Parametres : toggle theme clair/sombre/systeme, notifications, confidentialite
- Aide : FAQ expandable + formulaire de contact avec validation
- A propos : infos app, technologies, licence
- Theme clair + sombre (Material 3, seed color)
- Navigation adaptive : BottomNavigationBar (mobile) / NavigationRail (desktop)
- Animation scale sur le bouton "Ajouter au panier"

## Lancer l'application

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test
```
