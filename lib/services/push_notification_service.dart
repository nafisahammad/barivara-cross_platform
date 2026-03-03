import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'db_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final DbService _db = DbService.instance;

  String? _userId;
  String? _token;

  Future<void> init() async {
    // Firebase Messaging on web needs extra setup (service worker + VAPID key).
    // Skip initialization on web so the app can start.
    if (kIsWeb) return;

    await _messaging.requestPermission();
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    _token = await _messaging.getToken();
    if (_token != null) {
      await _saveToken(_token!);
    }

    _messaging.onTokenRefresh.listen((token) async {
      _token = token;
      await _saveToken(token);
    });

    FirebaseMessaging.onMessage.listen((message) {});
  }

  Future<void> bindUser(String userId) async {
    _userId = userId;
    final token = _token ?? await _messaging.getToken();
    if (token != null) {
      _token = token;
      await _saveToken(token);
    }
  }

  Future<void> clearUser() async {
    _userId = null;
  }

  Future<void> _saveToken(String token) async {
    final userId = _userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) return;
    await _db.users.doc(userId).set(
      {
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
      },
      SetOptions(merge: true),
    );
  }
}
