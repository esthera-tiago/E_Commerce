import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Détecteur de connectivité simulé, renvoyé par [mockConnectivityChannel].
///
/// L'état est mémorisé : la coupure peut être annoncée *avant* le lancement de
/// l'application, comme si l'utilisateur ouvrait l'application sans réseau, ou
/// *pendant* son utilisation, comme un train qui entre dans un tunnel.
class FakeConnectivity {
  FakeConnectivity(this._emit) : _types = const ['wifi'];

  final void Function(List<String>) _emit;
  List<String> _types;

  /// Annonce une coupure : `connectivity_plus` publie alors `['none']`.
  ///
  /// Si l'application écoute déjà, l'événement part immédiatement ; sinon il
  /// sera rejoué à la prochaine subscription.
  void goOffline() => _set(const ['none']);

  /// Annonce le retour du réseau.
  void goOnline() => _set(const ['wifi']);

  void _set(List<String> types) {
    _types = types;
    _emit(types);
  }

  /// Rejoue l'état mémorisé, comme le fait la plateforme à chaque abonnement.
  void replay() => _emit(_types);
}

/// Simule la présence du plugin `connectivity_plus` sur la plateforme de test.
///
/// Le plugin écoute un `EventChannel` que le runner de test ne sait pas servir.
/// Sans ce faux, l'activation du flux remonte une `MissingPluginException`
/// signalée par `ServicesBinding`, qui fait échouer le test alors que
/// l'application n'a rien fait de faux : le bandeau hors-ligne est une
/// commodité d'affichage, pas une dépendance fonctionnelle.
///
/// L'état initial est « connecté », ce qui correspond aux écrans au premier
/// lancement ; les tests basculent avec [FakeConnectivity.goOffline].
FakeConnectivity mockConnectivityChannel() {
  const name = 'dev.fluttercommunity.plus/connectivity_status';
  const channel = MethodChannel(name, StandardMethodCodec());
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final connectivity = FakeConnectivity((types) {
    messenger.handlePlatformMessage(
      name,
      channel.codec.encodeSuccessEnvelope(types),
      (_) {},
    );
  });

  messenger.setMockMessageHandler(name, (message) async {
    final call = channel.codec.decodeMethodCall(message);
    if (call.method == 'listen') {
      // Un `EventChannel` publie toujours un état à la subscription : c'est
      // ainsi que l'application démarre déjà hors-ligne si le test l'a demandé.
      connectivity.replay();
      return channel.codec.encodeSuccessEnvelope(null);
    }
    if (call.method == 'cancel') {
      return channel.codec.encodeSuccessEnvelope(null);
    }
    return null;
  });

  addTearDown(() => messenger.setMockMessageHandler(name, null));
  return connectivity;
}

/// Simule `path_provider`, utilisé par le cache des images distantes, et
/// renvoie la racine de stockage correspondante.
///
/// Le runner de test ne fournit pas de répertoire temporaire natif : sans ce
/// faux, la lecture du cache d'images remonte une `MissingPluginException`
/// qui fait échouer le test pour une raison étrangère à l'application.
///
/// Le chemin est volontairement **stable** d'un test à l'autre : le gestionnaire
/// de cache de `cached_network_image` est un singleton qui résout son répertoire
/// au premier usage et le conserve, donc un dossier régénéré à chaque test
/// deviendrait invisible pour lui.
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
