import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/di/providers.dart';
import 'core/storage/local_storage.dart';

/// Point d'entrée : les boîtes Hive sont ouvertes avant le premier rendu pour
/// que les repositories synchrones puissent y accéder dès leur création.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await LocalStorage.init();

  runApp(
    ProviderScope(
      overrides: [localStorageProvider.overrideWithValue(storage)],
      child: const ECommerceApp(),
    ),
  );
}
