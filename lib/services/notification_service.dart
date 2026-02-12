import '../models/app_notification.dart';
import 'db_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final DbService _db = DbService.instance;

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
