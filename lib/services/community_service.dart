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
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => CommunityMessage.fromMap(doc.id, doc.data()))
              .toList();
          messages.sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          return messages;
        });
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
