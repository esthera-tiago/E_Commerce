import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../core/di/providers.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/cart/presentation/cart_controller.dart';

/// Coquille adaptative : barre de navigation basse sur mobile, rail vertical
/// à partir de 800 px de largeur (téléphones en paysage, tablettes, web).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const breakpoint = 800.0;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  void _go(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    widget.navigationShell.goBranch(index, initialLocation: index == _index);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isSignedIn = ref.watch(
      authControllerProvider.select((s) => s.isAuthenticated),
    );
    final cartCount = ref.watch(
      cartControllerProvider.select((state) => state.itemCount),
    );
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppShell.breakpoint;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            _NavRail(
              index: _index,
              onDestinationSelected: _go,
              isSignedIn: isSignedIn,
              cartCount: cartCount,
            ),
          Expanded(
            child: Column(
              children: [
                const _NetworkStatusStrip(),
                Expanded(child: widget.navigationShell),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _go,
              destinations: _destinations(
                strings,
                cartCount: cartCount,
                isSignedIn: isSignedIn,
              ),
            ),
    );
  }

  List<NavigationDestination> _destinations(
    AppStrings strings, {
    required int cartCount,
    required bool isSignedIn,
  }) {
    return [
      NavigationDestination(
        icon: const Icon(Icons.storefront_outlined),
        selectedIcon: const Icon(Icons.storefront),
        label: strings.navShop,
      ),
      NavigationDestination(
        icon: const Icon(Icons.favorite_border),
        selectedIcon: const Icon(Icons.favorite),
        label: strings.navFavorites,
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: cartCount > 0,
          label: Text('$cartCount'),
          child: const Icon(Icons.shopping_bag_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: cartCount > 0,
          label: Text('$cartCount'),
          child: const Icon(Icons.shopping_bag),
        ),
        label: strings.navCart,
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: isSignedIn ? strings.myAccount : strings.navAccount,
      ),
    ];
  }
}

class _NavRail extends ConsumerWidget {
  const _NavRail({
    required this.index,
    required this.onDestinationSelected,
    required this.isSignedIn,
    required this.cartCount,
  });

  final int index;
  final ValueChanged<int> onDestinationSelected;
  final bool isSignedIn;
  final int cartCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    return NavigationRail(
      selectedIndex: index,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Icon(
          Icons.storefront,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
      ),
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.storefront_outlined),
          selectedIcon: const Icon(Icons.storefront),
          label: Text(strings.navShop),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.favorite_border),
          selectedIcon: const Icon(Icons.favorite),
          label: Text(strings.navFavorites),
        ),
        NavigationRailDestination(
          icon: Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: const Icon(Icons.shopping_bag),
          ),
          label: Text(strings.navCart),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: Text(isSignedIn ? strings.myAccount : strings.navAccount),
        ),
      ],
    );
  }
}

/// Bandeau persistant affiché sous la barre d'état lorsque l'appareil est hors
/// ligne : les données affichées proviennent alors du cache Hive.
class _NetworkStatusStrip extends ConsumerWidget {
  const _NetworkStatusStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    if (!isOffline) return const SizedBox.shrink();
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.tertiaryContainer,
      child: SizedBox(
        height: 28,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 14, color: scheme.onTertiaryContainer),
              const SizedBox(width: 6),
              Text(
                strings.offlineBanner,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
