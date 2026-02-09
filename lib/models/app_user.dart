import 'enums.dart';

class AppUser {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? buildingId;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.buildingId,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: (data['name'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      role: UserRole.values.byName((data['role'] ?? 'resident') as String),
      buildingId: data['buildingId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'role': role.name,
      'buildingId': buildingId,
    };
  }
}
