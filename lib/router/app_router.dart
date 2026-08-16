import 'package:go_router/go_router.dart';

import '../screens/about_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/help_screen.dart';
import '../screens/home_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (_, _) => const HomeScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      name: 'productDetail',
      builder: (_, state) => ProductDetailScreen(
        productId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/cart',
      name: 'cart',
      builder: (_, _) => const CartScreen(),
    ),
    GoRoute(
      path: '/favorites',
      name: 'favorites',
      builder: (_, _) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (_, _) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (_, _) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/help',
      name: 'help',
      builder: (_, _) => const HelpScreen(),
    ),
    GoRoute(
      path: '/about',
      name: 'about',
      builder: (_, _) => const AboutScreen(),
    ),
  ],
);
