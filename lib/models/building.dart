class Building {
  final String id;
  final String hostId;
  final String name;
  final String address;
  final String inviteCode;
  final List<String> rules;

  const Building({
    required this.id,
    required this.hostId,
    required this.name,
    required this.address,
    required this.inviteCode,
    required this.rules,
  });

  factory Building.fromMap(String id, Map<String, dynamic> data) {
    final rawRules = data['rules'];
    return Building(
      id: id,
      hostId: (data['hostId'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      address: (data['address'] ?? '') as String,
      inviteCode: (data['inviteCode'] ?? '') as String,
      rules: rawRules is Iterable ? rawRules.map((e) => e.toString()).toList() : <String>[],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'name': name,
      'address': address,
      'inviteCode': inviteCode,
      'rules': rules,
    };
  }
}
