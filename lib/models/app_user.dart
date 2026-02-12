import 'enums.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? buildingId;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.buildingId,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    final rawEmail = (data['email'] ?? data['phone'] ?? '') as String;
    return AppUser(
      id: id,
      name: (data['name'] ?? '') as String,
      email: rawEmail,
      role: UserRole.values.byName((data['role'] ?? 'resident') as String),
      buildingId: data['buildingId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'buildingId': buildingId,
    };
  }
}
