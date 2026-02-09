class Contact {
  final String id;
  final String buildingId;
  final String name;
  final String phone;
  final String category;

  const Contact({
    required this.id,
    required this.buildingId,
    required this.name,
    required this.phone,
    required this.category,
  });

  factory Contact.fromMap(String id, Map<String, dynamic> data) {
    return Contact(
      id: id,
      buildingId: (data['buildingId'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      category: (data['category'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'name': name,
      'phone': phone,
      'category': category,
    };
  }
}
