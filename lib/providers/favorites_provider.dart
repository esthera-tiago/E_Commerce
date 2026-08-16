import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences instance (loaded once).
final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// Favorites state persisted in SharedPreferences.
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).valueOrNull;
  return FavoritesNotifier(prefs);
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this._prefs)
      : super(Set<String>.from(_prefs?.getStringList('favorites') ?? []));

  final SharedPreferences? _prefs;

  bool isFavorite(String id) => state.contains(id);

  void toggle(String id) {
    final next = Set<String>.from(state);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    _save();
  }

  void _save() {
    _prefs?.setStringList('favorites', state.toList());
  }
}
