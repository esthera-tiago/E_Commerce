import 'package:e_commerce_app/core/storage/json_cache_store.dart';

/// Faux cache JSON en mémoire, équivalent de `JsonCacheStore` sans Hive.
///
/// Un mock ne conviendrait pas : `read<T>` est générique, et les assertions
/// portent ici sur le *contenu réellement écrit* (par exemple « aucun jeton
/// n'atterrit dans Hive »), ce qu'un fauxStore rend vérifiable.
class FakeJsonCacheStore implements JsonCacheStore {
  final Map<String, Object?> entries = <String, Object?>{};

  /// Date d'écriture de chaque clé, pour `ageOf`.
  final Map<String, DateTime> writtenAt = <String, DateTime>{};

  @override
  Future<void> write(String key, Object payload, {bool merge = false}) async {
    if (merge) {
      final existing = entries[key];
      if (existing is Map<String, dynamic>) {
        entries[key] = {...existing, ...(payload as Map<String, dynamic>)};
        writtenAt[key] = DateTime.now();
        return;
      }
    }
    entries[key] = payload;
    writtenAt[key] = DateTime.now();
  }

  @override
  Future<T?> read<T>(String key, {Duration? maxAge}) async {
    if (!entries.containsKey(key)) return null;
    if (maxAge != null) {
      final age = DateTime.now().difference(writtenAt[key]!);
      if (age > maxAge) return null;
    }
    final value = entries[key];
    return value is T ? value : null;
  }

  @override
  Future<Duration?> ageOf(String key) async {
    final at = writtenAt[key];
    return at == null ? null : DateTime.now().difference(at);
  }

  @override
  Future<bool> has(String key) async => entries.containsKey(key);

  @override
  Future<void> remove(String key) async {
    entries.remove(key);
    writtenAt.remove(key);
  }

  @override
  Future<void> clear() async {
    entries.clear();
    writtenAt.clear();
  }

  /// Recherche récursive d'une valeur dans toutes les entrées : sert à vérifier
  /// qu'aucun secret n'a été écrit dans le cache.
  bool containsValue(String needle) {
    bool walk(Object? value) {
      if (value is String) return value.contains(needle);
      if (value is Map) return value.values.any(walk);
      if (value is Iterable) return value.any(walk);
      return false;
    }

    return entries.values.any(walk);
  }
}
