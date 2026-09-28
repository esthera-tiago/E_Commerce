import 'dart:convert';

import 'package:e_commerce_app/core/error/error_mapper.dart';
import 'package:e_commerce_app/core/error/failure.dart';
import 'package:e_commerce_app/core/storage/credential_store.dart';
import 'package:e_commerce_app/core/storage/token_store.dart';
import 'package:e_commerce_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:e_commerce_app/features/auth/data/models/auth_response_dto.dart';
import 'package:e_commerce_app/features/auth/data/models/user_dto.dart';
import 'package:e_commerce_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fake_json_cache_store.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockTokenStore extends Mock implements TokenStore {}

class _MockCredentialStore extends Mock implements CredentialStore {}

/// Couvre les deux origines de session (jeton API / compte local) ainsi que
/// les garde-fous qui empêchent de laisser un profil « connecté » sans jeton.
void main() {
  const profileKey = 'auth_profile';
  const kindKey = 'auth_session_kind';

  late _MockRemote remote;
  late _MockTokenStore tokenStore;
  late _MockCredentialStore credentials;
  late FakeJsonCacheStore cache;
  late AuthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_pair());
  });

  setUp(() {
    remote = _MockRemote();
    tokenStore = _MockTokenStore();
    credentials = _MockCredentialStore();
    cache = FakeJsonCacheStore();

    // Par défaut : aucun jeton, aucun profil, aucune session locale.
    when(() => tokenStore.read()).thenAnswer((_) async => null);
    when(() => tokenStore.save(any())).thenAnswer((_) async {});
    when(() => tokenStore.clear()).thenAnswer((_) async {});

    repository = AuthRepositoryImpl(
      remote: remote,
      tokenStore: tokenStore,
      credentialStore: credentials,
      cache: cache,
    );
  });

  group('login — compte connu de l’API', () {
    test('stocke les jetons et met le profil en cache', () async {
      when(
        () => remote.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => AuthResponseDto(user: _userDto(), tokens: _pair()),
      );

      final user = await repository.login(
        username: 'emilys',
        password: 'emilyspass',
      );

      expect(user.username, 'emilys');
      expect(user.id, 7);
      // Les jetons vont dans le stockage chiffré, jamais dans Hive.
      verify(() => tokenStore.save(any())).called(1);
      expect(await cache.read<Map<String, dynamic>>(profileKey), isNotNull);
      expect(await cache.read<String>(kindKey), 'api');
      expect(
        cache.containsValue('signature'),
        isFalse,
        reason: 'aucun JWT ne doit être écrit dans le cache Hive',
      );
      verifyNever(
        () => credentials.verify(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      );
    });

    test('refuse une réponse d’authentification sans jeton', () async {
      when(
        () => remote.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => AuthResponseDto(
          user: _userDto(),
          tokens: const TokenPair(accessToken: '', refreshToken: ''),
        ),
      );

      await expectLater(
        repository.login(username: 'emilys', password: 'x'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            isA<ValidationFailure>(),
          ),
        ),
      );
    });
  });

  group('login — repli sur les comptes locaux', () {
    setUp(() {
      when(
        () => remote.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const ApiException(
          UnauthorizedFailure(debugMessage: 'Invalid credentials'),
        ),
      );
    });

    test('authentifie un compte créé sur l’appareil', () async {
      when(
        () => credentials.verify(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => CredentialCheck.valid);
      when(
        () => credentials.readProfile(any()),
      ).thenAnswer((_) async => _userDto().toJson());

      final user = await repository.login(
        username: 'local',
        password: 'secret',
      );

      expect(user.username, 'emilys');
      verifyNever(() => tokenStore.save(any()));
      expect(await cache.read<String>(kindKey), 'local');
    });

    test('remonte un mot de passe erroné', () async {
      when(
        () => credentials.verify(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => CredentialCheck.wrongPassword);

      await expectLater(
        repository.login(username: 'local', password: 'bad'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            isA<UnauthorizedFailure>(),
          ),
        ),
      );
    });

    test('remonte un utilisateur inconnu', () async {
      when(
        () => credentials.verify(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => CredentialCheck.unknownUser);

      await expectLater(
        repository.login(username: 'ghost', password: 'bad'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            isA<UnauthorizedFailure>(),
          ),
        ),
      );
      verifyNever(() => credentials.readProfile(any()));
    });

    test('ne masque pas une panne réseau', () async {
      when(
        () => remote.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const ApiException(NetworkFailure()));

      await expectLater(
        repository.login(username: 'emilys', password: 'emilyspass'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            isA<NetworkFailure>(),
          ),
        ),
      );
      verifyNever(
        () => credentials.verify(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      );
    });

    test('ne masque pas une erreur serveur 5xx', () async {
      when(
        () => remote.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const ApiException(ServerFailure(statusCode: 503)));

      await expectLater(
        repository.login(username: 'emilys', password: 'emilyspass'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            isA<ServerFailure>(),
          ),
        ),
      );
      verifyNever(
        () => credentials.verify(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      );
    });
  });

  group('hasSession', () {
    test('vraie avec un couple de jetons non expiré', () async {
      when(() => tokenStore.read()).thenAnswer((_) async => _pair());

      expect(await repository.hasSession(), isTrue);
    });

    test('faux quand le refresh token est expiré', () async {
      when(
        () => tokenStore.read(),
      ).thenAnswer((_) async => _pair(ttl: const Duration(hours: -1)));

      expect(await repository.hasSession(), isFalse);
      verify(() => tokenStore.clear()).called(1);
    });

    test('vraie pour un compte local dont le profil est en cache', () async {
      await cache.write(kindKey, 'local');
      await cache.write(profileKey, _userDto().toJson());

      expect(await repository.hasSession(), isTrue);
    });

    test('faux pour un profil API résiduel sans jeton', () async {
      // Le cas qui rend indispensable le marqueur d'origine de session :
      // jetons expirés + profil encore en cache => l'utilisateur n'est plus
      // authentifié.
      await cache.write(kindKey, 'api');
      await cache.write(profileKey, _userDto().toJson());

      expect(await repository.hasSession(), isFalse);
    });

    test('faux sans jeton ni profil', () async {
      expect(await repository.hasSession(), isFalse);
    });
  });

  group('restoreSession', () {
    test('relit le profil en cache hors-ligne', () async {
      await cache.write(kindKey, 'local');
      await cache.write(profileKey, _userDto().toJson());

      final user = await repository.restoreSession();

      expect(user?.email, 'emilys@example.test');
    });

    test('renvoie null quand aucune session n’existe', () async {
      expect(await repository.restoreSession(), isNull);
    });
  });

  group('fetchProfile', () {
    test('met à jour le cache profil depuis l’API', () async {
      when(() => remote.fetchProfile(7)).thenAnswer((_) async => _userDto());

      final user = await repository.fetchProfile(7);

      expect(user.id, 7);
      expect(await cache.has(profileKey), isTrue);
    });

    test('retombe sur le cache hors-ligne', () async {
      when(
        () => remote.fetchProfile(7),
      ).thenThrow(const ApiException(NetworkFailure()));
      await cache.write(profileKey, _userDto().toJson());

      final user = await repository.fetchProfile(7);

      expect(user.username, 'emilys');
    });

    test('propage une erreur serveur', () async {
      when(
        () => remote.fetchProfile(7),
      ).thenThrow(const ApiException(ServerFailure(statusCode: 500)));

      await expectLater(
        repository.fetchProfile(7),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('register', () {
    test('crée le compte côté API puis l’enregistre localement', () async {
      when(() => credentials.exists(any())).thenAnswer((_) async => false);
      when(
        () => remote.register(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _userDto(username: 'nouveau'));
      when(
        () => credentials.save(
          username: any(named: 'username'),
          password: any(named: 'password'),
          profile: any(named: 'profile'),
        ),
      ).thenAnswer((_) async {});

      final user = await repository.register(
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: 'ada@example.test',
        username: 'nouveau',
        password: 'secret6',
      );

      expect(user.username, 'nouveau');
      verify(
        () => credentials.save(
          username: 'nouveau',
          password: 'secret6',
          profile: any(named: 'profile'),
        ),
      ).called(1);
      expect(await cache.read<String>(kindKey), 'local');
      verifyNever(() => tokenStore.save(any()));
    });

    test('refuse un identifiant déjà pris sur l’appareil', () async {
      when(() => credentials.exists(any())).thenAnswer((_) async => true);

      await expectLater(
        repository.register(
          firstName: 'Ada',
          lastName: 'Lovelace',
          email: 'ada@example.test',
          username: 'nouveau',
          password: 'secret6',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            isA<ValidationFailure>(),
          ),
        ),
      );
      verifyNever(
        () => remote.register(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      );
    });
  });

  group('refresh', () {
    test('renouvelle et persiste un nouveau couple de jetons', () async {
      when(() => tokenStore.read()).thenAnswer((_) async => _pair());
      final stale = _pair();
      when(() => tokenStore.read()).thenAnswer((_) async => stale);
      when(
        () => remote.refresh(any()),
      ).thenAnswer((_) async => _pair(ttl: const Duration(hours: 2)));

      final renewed = await repository.refresh();

      expect(renewed, isNotNull);
      expect(renewed!.accessToken, isNot(stale.accessToken));
      verify(() => tokenStore.save(renewed)).called(1);
    });

    test('renvoie null quand le serveur refuse le refresh', () async {
      when(() => tokenStore.read()).thenAnswer((_) async => _pair());
      when(
        () => remote.refresh(any()),
      ).thenThrow(const ApiException(UnauthorizedFailure()));

      expect(await repository.refresh(), isNull);
      verifyNever(() => tokenStore.save(any()));
    });

    test('renvoie null sans jeton stocké', () async {
      expect(await repository.refresh(), isNull);
    });
  });

  test('logout efface jetons, profil et marqueur de session', () async {
    await repository.logout();

    verify(() => tokenStore.clear()).called(1);
    expect(await cache.has(profileKey), isFalse);
    expect(await cache.has(kindKey), isFalse);
  });
}

UserDto _userDto({String username = 'emilys'}) => UserDto(
  id: 7,
  username: username,
  email: 'emilys@example.test',
  firstName: 'Emily',
  lastName: 'Johnson',
);

/// Jeton JWT factice : le repository ne lit que le payload (`exp`), jamais la
/// signature. La signature n'a donc pas besoin d'être valide.
TokenPair _pair({Duration ttl = const Duration(hours: 1)}) =>
    TokenPair(accessToken: _jwt(ttl), refreshToken: _jwt(ttl));

String _jwt(Duration ttl) {
  const header = '{"alg":"HS256","typ":"JWT"}';
  final exp = DateTime.now().add(ttl).millisecondsSinceEpoch ~/ 1000;
  final payload = jsonEncode({'id': 7, 'exp': exp});
  return '${_b64(header)}.${_b64(payload)}.signature';
}

String _b64(String value) =>
    base64Url.encode(utf8.encode(value)).replaceAll('=', '');
