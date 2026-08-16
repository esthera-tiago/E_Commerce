import 'package:flutter/foundation.dart';

@immutable
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.memberSince = '',
    this.loyaltyPoints = 0,
  });

  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String memberSince;
  final int loyaltyPoints;

  factory User.mock() {
    return const User(
      id: 'u1',
      name: 'Amina Teko',
      email: 'amina.teko@email.com',
      avatarUrl: '',
      memberSince: 'Janvier 2024',
      loyaltyPoints: 1250,
    );
  }
}
