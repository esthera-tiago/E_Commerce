import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../core/di/providers.dart';
import '../../../features/settings/presentation/settings_controller.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/auth_repository.dart';

/// Phase du cycle de vie de la session.
enum AuthStatus {
  /// Démarrage : lecture du stockage chiffré et du cache de profil.
  restoring,

  /// Aucune session valide : l'utilisateur doit se connecter.
  unauthenticated,

  /// Session établie.
  authenticated,

  /// Opération réseau en cours (bouton en état de chargement).
  submitting,
}

/// État exposé à l'interface pour la feature authentification.
@immutable
class AuthState {
  const AuthState({this.status = AuthStatus.restoring, this.user, this.error});

  final AuthStatus status;
  final AppUser? user;

  /// Message déjà traduit, prêt à être affiché.
  final String? error;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  bool get isBusy =>
      status == AuthStatus.submitting || status == AuthStatus.restoring;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Orchestration de la session.
///
/// C'est le **seul** emplacement qui décide si l'utilisateur est authentifié :
/// le routeur observe ce controller pour rediriger, ce qui évite qu'un écran
/// implémente sa propre logique de garde.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _observeSessionExpiry();
    restore();
  }

  final Ref _ref;

  AuthRepository get _repository => _ref.read(authRepositoryProvider);

  /// Restaure la session au lancement, puis observe l'expiration des jetons.
  Future<void> restore() async {
    try {
      final user = await _repository.restoreSession();
      state = user == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(status: AuthStatus.authenticated, user: user);
    } on ApiException {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Quand l'intercepteur ne parvient plus à renouveler un jeton, il
  /// incrémente ce compteur. L'écouter transforme ce signal technique en
  /// déconnexion, sans que l'UI connaisse l'existence de l'intercepteur.
  void _observeSessionExpiry() {
    _ref.listen<int>(sessionExpiredProvider, (previous, next) {
      if (previous == null || next <= previous) return;
      if (state.isAuthenticated) logout();
    });
  }

  Future<bool> login({required String username, required String password}) {
    return _submit(
      () => _repository.login(username: username, password: password),
    );
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
  }) {
    return _submit(
      () => _repository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        username: username,
        password: password,
      ),
    );
  }

  /// Recharge le profil depuis l'API. Les erreurs sont absorbées : l'écran de
  /// profil affiche déjà une donnée en cache, la rafraîchir est un bonus.
  Future<void> refreshProfile() async {
    final user = state.user;
    if (user == null) return;
    try {
      final fresh = await _repository.fetchProfile(user.id);
      state = state.copyWith(user: fresh, clearError: true);
    } on ApiException {
      // Le cache reste la source affichée.
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() => state = state.copyWith(clearError: true);

  /// Le repository ne connaît pas les chaînes de l'interface : la traduction
  /// passe par la table partagée, lisible sans `BuildContext`.
  Future<bool> _submit(Future<AppUser> Function() action) async {
    state = state.copyWith(status: AuthStatus.submitting, clearError: true);
    try {
      final user = await action();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on ApiException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _ref.read(appStringsProvider).failure(error.failure),
      );
      return false;
    } on Object catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _ref.read(appStringsProvider).failure(ErrorMapper.map(error)),
      );
      return false;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Session courante, ou `null` si personne n'est connecté.
final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authControllerProvider).user,
);

final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authControllerProvider).isAuthenticated,
);
