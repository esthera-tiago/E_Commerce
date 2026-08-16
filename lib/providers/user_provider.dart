import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';

/// Mock user profile (constant across the app).
final userProvider = Provider<User>((ref) {
  return User.mock();
});
