import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'favorites_provider.dart';

/// User-submitted ratings keyed by product ID.
/// Stored as JSON-encoded map in SharedPreferences.
final userRatingsProvider =
    StateNotifierProvider<UserRatingsNotifier, Map<String, int>>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).valueOrNull;
  return UserRatingsNotifier(prefs);
});

class UserRatingsNotifier extends StateNotifier<Map<String, int>> {
  UserRatingsNotifier(this._prefs) : super(_loadFromPrefs(_prefs));

  final SharedPreferences? _prefs;

  static Map<String, int> _loadFromPrefs(SharedPreferences? prefs) {
    if (prefs == null) return {};
    final raw = prefs.getStringList('user_ratings') ?? [];
    final map = <String, int>{};
    for (final entry in raw) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        map[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
    return map;
  }

  void rate(String productId, int stars) {
    state = {...state, productId: stars};
    _save();
  }

  void removeRating(String productId) {
    state = {...state}..remove(productId);
    _save();
  }

  int getRating(String productId) => state[productId] ?? 0;

  void _save() {
    final raw = state.entries.map((e) => '${e.key}:${e.value}').toList();
    _prefs?.setStringList('user_ratings', raw);
  }
}
