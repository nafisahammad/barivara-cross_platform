import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/community_message.dart';
import 'db_service.dart';

class CommunityService {
  CommunityService._();

  static final CommunityService instance = CommunityService._();

  final DbService _db = DbService.instance;

  Stream<List<CommunityMessage>> streamMessages(String buildingId) {
    return _db.community
        .where('buildingId', isEqualTo: buildingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CommunityMessage.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> sendMessage({
    required String buildingId,
    required String userId,
    required String userName,
    required String flatNumber,
    required String content,
    String? mediaData,
  }) async {
    await _db.community.add({
      'buildingId': buildingId,
      'userId': userId,
      'userName': userName,
      'flatNumber': flatNumber,
      'content': content,
      'mediaData': mediaData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
