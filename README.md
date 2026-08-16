# E-Commerce App — She4Tech Boutique

Application e-commerce Flutter premium alimentee par **Riverpod** pour la gestion d'etat.

## Architecture

```
lib/
  main.dart                          # Point d'entree, ProviderScope
  app.dart                           # MaterialApp.router + theme toggle
  router/
    app_router.dart                  # GoRouter — 5 routes
  theme/
    app_theme.dart                   # Material 3 light + dark (seed #1A1A2E)
  models/
    product.dart                     # Product (immutable, copyWith, fromJson)
    cart_item.dart                   # CartItem (Product + quantity)
    user.dart                        # User (mock profile)
    filter_state.dart                # FilterState + SortOption enum
  data/
    products.json                    # 20 produits mok sur 6 categories
    product_repository.dart          # Chargement asset + cache memoire
  providers/
    product_provider.dart            # productList, categories, filter, filteredProducts
    cart_provider.dart               # cart (StateNotifier), cartTotal, cartItemCount
    favorites_provider.dart          # sharedPrefs, favorites (persiste localement)
    filter_provider.dart             # (inclus dans product_provider)
    user_provider.dart               # user (mock)
  screens/
    home_screen.dart                 # Catalogue (grille, recherche, filtres)
    product_detail_screen.dart       # Detail produit
    cart_screen.dart                 # Panier + commande
    favorites_screen.dart            # Favoris
    profile_screen.dart              # Profil mock
  widgets/
    adaptive_scaffold.dart           # Responsive (NavigationRail / BottomBar)
    filter_bar.dart                  # Recherche + chips categorie + tri
    product_card.dart                # Carte produit avec favori + panier
    animated_cart_button.dart        # Bouton avec animation scale
    cart_item_tile.dart              # Ligne panier avec +/-
```

## Providers (10 au total)

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
| `userProvider` | `Provider<User>` | Profil mock |

## Fonctionnalites

- Catalogue avec grille responsive et cartes produit
- Detail produit avec notation et avis
- Panier : ajout, suppression, modification de quantite, total dynamique
- Favoris : toggle persiste via SharedPreferences
- Recherche textuelle, filtrage par categorie, tri (prix, note, recents)
- Profil mock avec points fidelite
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
