import 'firestore_utils.dart';

class Notice {
  final String id;
  final String buildingId;
  final String title;
  final String body;
  final DateTime? createdAt;

  const Notice({
    required this.id,
    required this.buildingId,
    required this.title,
    required this.body,
    this.createdAt,
  });

  factory Notice.fromMap(String id, Map<String, dynamic> data) {
    return Notice(
      id: id,
      buildingId: (data['buildingId'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      body: (data['body'] ?? '') as String,
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'title': title,
      'body': body,
      'createdAt': toTimestamp(createdAt),
    };
  }
}
