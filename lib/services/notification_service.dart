import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';
import 'db_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final DbService _db = DbService.instance;

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _db.notifications.add({
      'userId': userId,
      'title': title,
      'body': body,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.pushNotifications.add({
      'userId': userId,
      'title': title,
      'body': body,
      'data': data ?? const {},
      'sent': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AppNotification>> streamNotificationsForUser(String userId) {
    return _db.notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
