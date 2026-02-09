import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums.dart';
import '../models/resident_link.dart';
import 'db_service.dart';

class ResidentService {
  ResidentService._();

  static final ResidentService instance = ResidentService._();

  final DbService _db = DbService.instance;

  Future<ResidentLink> requestAccess({
    required String userId,
    required String buildingId,
    required String flatId,
  }) async {
    final doc = _db.residents.doc();
    final link = ResidentLink(
      id: doc.id,
      userId: userId,
      buildingId: buildingId,
      flatId: flatId,
      approvalStatus: ApprovalStatus.pending,
      createdAt: DateTime.now(),
    );

    await doc.set({
      ...link.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return link;
  }

  Future<ResidentLink?> getLinkForUser(String userId) async {
    final query = await _db.residents.where('userId', isEqualTo: userId).limit(1).get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return ResidentLink.fromMap(doc.id, doc.data());
  }
}
