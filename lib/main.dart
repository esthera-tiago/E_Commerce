import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/di/providers.dart';
import 'core/storage/local_storage.dart';

/// Taille maximale du cache d'images décodées, en octets.
///
/// Le défaut de Flutter (100 Mo) laisse un catalogue faire cohabiter des
/// dizaines de vignettes en pleine résolution. Comme les images sont désormais
/// décodées à leur taille d'affichage, 96 Mo suffisent largement et le budget
/// mémoire reste prévisible sur un appareil d'entrée de gamme.
const int imageCacheBudgetBytes = 96 << 20;

/// Point d'entrée : les boîtes Hive sont ouvertes avant le premier rendu pour
/// que les repositories synchrones puissent y accéder dès leur création.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = imageCacheBudgetBytes;

  final storage = await LocalStorage.init();

  runApp(
    ProviderScope(
      overrides: [localStorageProvider.overrideWithValue(storage)],
      child: const ECommerceApp(),
    ),
  );
}
