import 'firestore_utils.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.read,
    this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      userId: (data['userId'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      body: (data['body'] ?? '') as String,
      read: (data['read'] ?? false) as bool,
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'read': read,
      'createdAt': toTimestamp(createdAt),
    };
  }
}
