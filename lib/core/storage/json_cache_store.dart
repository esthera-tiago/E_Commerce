import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

/// Noms des boîtes Hive. Centralisés pour éviter toute collision de clé.
abstract final class CacheBoxes {
  static const String products = 'products_cache';
  static const String categories = 'categories_cache';
  static const String orders = 'orders_cache';
  static const String profile = 'profile_cache';
  static const String favorites = 'favorites_cache';
  static const String cart = 'cart_cache';
  static const String preferences = 'preferences_cache';
}

/// Couche de persistance locale basée sur Hive, sérialisée en JSON.
///
/// Stocker du JSON plutôt que des objets Hive typés évite la génération de
/// code (`build_runner`) et garde le cache interopérable avec le format de
/// l'API : une réponse serveur peut être écrite telle quelle puis relue.
class JsonCacheStore {
  JsonCacheStore(this._box);

  final Box<dynamic> _box;

  /// Ouvre (ou crée) une boîte Hive. L'appelant doit avoir initialisé Hive.
  static Future<JsonCacheStore> open(String name) async {
    final box = await Hive.openBox<dynamic>(name);
    return JsonCacheStore(box);
  }

  /// Écrit une valeur JSON et horodate l'entrée.
  ///
  /// Une écriture en cache ne doit jamais faire échouer la requête réseau en
  /// cours : les erreurs sont volontairement absorbées.
  ///
  /// [merge] fusionne la charge utile dans un objet existant au lieu de la
  /// remplacer. Utilisé par les préférences, où chaque réglage est écrit
  /// indépendamment des autres.
  Future<void> write(String key, Object payload, {bool merge = false}) async {
    try {
      var value = payload;
      if (merge) {
        final existing = await read<Map<String, dynamic>>(key);
        value = {...?existing, ...(payload as Map<String, dynamic>)};
      }
      await _box.put(
        key,
        jsonEncode({
          'writtenAt': DateTime.now().toIso8601String(),
          'payload': value,
        }),
      );
    } on Object {
      // Cache best-effort : une écriture ratée n'affecte pas l'expérience.
    }
  }

  /// Relit une valeur JSON. Retourne `null` si absente, illisible ou périmée.
  Future<T?> read<T>(String key, {Duration? maxAge}) async {
    try {
      final raw = _box.get(key);
      if (raw is! String) return null;

      final envelope = jsonDecode(raw);
      if (envelope is! Map<String, dynamic>) return null;

      final writtenAt = DateTime.tryParse(
        envelope['writtenAt'] as String? ?? '',
      );
      if (writtenAt == null) return null;

      if (maxAge != null && DateTime.now().difference(writtenAt) > maxAge) {
        return null;
      }
      return envelope['payload'] as T?;
    } on Object {
      return null;
    }
  }

  /// Retourne l'âge de l'entrée, `null` si elle n'existe pas. Sert à afficher
  /// « données mises à jour il y a X ».
  Future<Duration?> ageOf(String key) async {
    try {
      final raw = _box.get(key);
      if (raw is! String) return null;
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final writtenAt = DateTime.tryParse(
        envelope['writtenAt'] as String? ?? '',
      );
      if (writtenAt == null) return null;
      return DateTime.now().difference(writtenAt);
    } on Object {
      return null;
    }
  }

  Future<bool> has(String key) async => _box.containsKey(key);

  Future<void> remove(String key) async {
    try {
      await _box.delete(key);
    } on Object {
      // Ignoré : la suppression est best-effort.
    }
  }

  Future<void> clear() async {
    try {
      await _box.clear();
    } on Object {
      // Ignoré.
    }
  }
}
