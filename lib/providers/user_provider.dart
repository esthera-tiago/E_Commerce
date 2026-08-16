import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'favorites_provider.dart';

final editableUserProvider =
    StateNotifierProvider<EditableUserNotifier, User>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).valueOrNull;
  return EditableUserNotifier(prefs);
});

class EditableUserNotifier extends StateNotifier<User> {
  EditableUserNotifier(this._prefs)
      : super(_load(_prefs));

  final SharedPreferences? _prefs;

  static User _load(SharedPreferences? prefs) {
    if (prefs == null) return User.mock();
    final name = prefs.getString('user_name');
    final email = prefs.getString('user_email');
    if (name == null || email == null) return User.mock();
    return User(
      id: 'u1',
      name: name,
      email: email,
      memberSince: prefs.getString('user_member_since') ?? 'Janvier 2024',
      loyaltyPoints: prefs.getInt('user_loyalty_points') ?? 1250,
    );
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
    _save();
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email);
    _save();
  }

  void _save() {
    _prefs?.setString('user_name', state.name);
    _prefs?.setString('user_email', state.email);
  }
}
