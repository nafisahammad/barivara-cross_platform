class UserPassword {
  final String id;
  final String value;

  const UserPassword({
    required this.id,
    required this.value,
  });

  factory UserPassword.fromMap(String id, Map<String, dynamic> data) {
    return UserPassword(
      id: id,
      value: (data['value'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
    };
  }
}
