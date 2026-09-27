import '../../domain/entities/app_user.dart';

/// Data Transfer Object du profil utilisateur renvoyé par l'API.
///
/// Isole le format JSON de l'entité métier : si la réponse de l'API change,
/// seule cette classe est modifiée.
class UserDto {
  const UserDto({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.gender = '',
    this.image = '',
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;

  /// Méthodes défensives : l'API renvoie des champs parfois `null` ou absents,
  /// une conversion directe `(json['id'] as int)` planterait à l'exécution.
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: _toInt(json['id']) ?? 0,
      username: _toString(json['username']),
      email: _toString(json['email']),
      firstName: _toString(json['firstName']),
      lastName: _toString(json['lastName']),
      gender: _toString(json['gender']),
      image: _toString(json['image']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'gender': gender,
    'image': image,
  };

  /// Projection vers l'entité domaine.
  AppUser toEntity() => AppUser(
    id: id,
    username: username,
    email: email,
    firstName: firstName,
    lastName: lastName,
    gender: gender,
    avatarUrl: image,
  );

  /// Reconstruit un utilisateur depuis le cache local (JSON déjà décodé).
  factory UserDto.fromCache(Map<String, dynamic> json) =>
      UserDto.fromJson(json);

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _toString(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }
}
