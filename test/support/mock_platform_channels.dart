import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simule la présence du plugin `connectivity_plus` sur la plateforme de test.
///
/// Le plugin écoute un `EventChannel` que le runner de test ne sait pas servir.
/// Sans ce faux, l'activation du flux remonte une `MissingPluginException`
/// signalée par `ServicesBinding`, qui fait échouer le test alors que
/// l'application n'a rien fait de faux : le bandeau hors-ligne est une
/// commodité d'affichage, pas une dépendance fonctionnelle.
///
/// Le flux simulé n'envoie jamais d'événement, ce qui correspond à une
/// application connectée — l'état par défaut des écrans.
void mockConnectivityChannel() {
  const name = 'dev.fluttercommunity.plus/connectivity_status';
  const channel = MethodChannel(name, StandardMethodCodec());
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMessageHandler(name, (message) async {
    final call = channel.codec.decodeMethodCall(message);
    if (call.method == 'listen' || call.method == 'cancel') {
      return channel.codec.encodeSuccessEnvelope(null);
    }
    return null;
  });

  addTearDown(() => messenger.setMockMessageHandler(name, null));
}

/// Simule `path_provider`, utilisé par le cache des images distantes, et
/// renvoie la racine de stockage correspondante.
///
/// Le runner de test ne fournit pas de répertoire temporaire natif : sans ce
/// faux, la lecture du cache d'images remonte une `MissingPluginException`
/// qui fait échouer le test pour une raison étrangère à l'application.
///
/// Le chemin est volontairement **stable** d'un test à l'autre : le gestionnaire
/// de cache de `cached_network_image` est un singleton qui résout son
/// répertoire au premier usage et le conserve, donc un dossier régénéré à
/// chaque test deviendrait invisible pour lui. Les tests réamorcent le contenu
/// à chaque fois avec `seedCachedImage`.
Directory mockPathProviderChannel() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final root = Directory(
    '${Directory.systemTemp.path}/e_commerce_test_storage',
  );

  messenger.setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'getTemporaryDirectory':
      case 'getApplicationSupportDirectory':
      case 'getApplicationDocumentsDirectory':
      case 'getApplicationCacheDirectory':
      case 'getExternalCacheDirectory':
      case 'getExternalStorageDirectory':
      case 'getDownloadsDirectory':
        return root.path;
    }
    return null;
  });

  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

  return root;
}
