import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/catalog/presentation/screens/home_screen.dart';
import '../../features/catalog/presentation/screens/product_detail_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/help_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../shell/app_shell.dart';

/// Clés de navigation réutilisées par le routeur et par les widgets qui
/// voulez rediriger l'utilisateur (bouton « retry », panier, etc.).
abstract final class Routes {
  static const login = '/login';
  static const shop = '/shop';
  static const product = '/shop/product/:id';
  static const search = '/shop/search';
  static const favorites = '/favorites';
  static const cart = '/cart';
  static const account = '/account';
  static const orders = '/account/orders';
  static const settings = '/account/settings';
  static const help = '/help';
  static const about = '/about';

  static String productDetail(int id) => '/shop/product/$id';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Routeur applicatif : arborescence des onglets, fiches produit empilées et
/// redirection automatique vers la connexion tant que la session n'est pas
/// établie.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.shop,
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final status = ref.read(authControllerProvider);
      final onLogin = state.matchedLocation == Routes.login;
      final signingIn = status.isBusy;

      // Pendant la soumission du formulaire on ne redirige pas : sinon la
      // navigation repartirait sur /login et masquerait l'erreur affichée.
      if (onLogin) {
        return status.isAuthenticated ? Routes.shop : null;
      }
      if (!status.isAuthenticated) return signingIn ? null : Routes.login;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.shop,
                builder: (context, state) => HomeScreen(
                  onOpenProduct: (id) => context.push(Routes.productDetail(id)),
                ),
                routes: [
                  GoRoute(
                    path: 'product/:id',
                    builder: (context, state) => ProductDetailScreen(
                      productId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.favorites,
                builder: (context, state) => FavoritesScreen(
                  onOpenProduct: (id) => context.push(Routes.productDetail(id)),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.cart,
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.account,
                builder: (context, state) => ProfileScreen(
                  onOpenOrders: () => context.push(Routes.orders),
                ),
                routes: [
                  GoRoute(
                    path: 'orders',
                    builder: (context, state) => const OrdersScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => SettingsScreen(
                      onOpenHelp: () => context.push(Routes.help),
                      onOpenAbout: () => context.push(Routes.about),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.help,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            HelpScreen(onOpenAbout: () => context.push(Routes.about)),
      ),
      GoRoute(
        path: Routes.about,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        _RouteNotFound(location: state.uri.toString()),
  );
});

/// Relance l'évaluation du `redirect` dès que le statut d'authentification
/// change, sans reconstruire le routeur (l'état de navigation est préservé).
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated ||
          previous?.isBusy != next.isBusy) {
        notifyListeners();
      }
    });
  }
}

class _RouteNotFound extends StatelessWidget {
  const _RouteNotFound({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text('404 — $location'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go(Routes.shop),
              child: const Text('Retour à la boutique'),
            ),
          ],
        ),
      ),
    );
  }
}
