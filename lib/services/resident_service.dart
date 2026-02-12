import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/flat.dart';
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

    await doc.set({...link.toMap(), 'createdAt': FieldValue.serverTimestamp()});

    // Notify host that a resident has requested access.
    final buildingSnapshot = await _db.buildings.doc(buildingId).get();
    final userSnapshot = await _db.users.doc(userId).get();
    final flatSnapshot = await _db.flats.doc(flatId).get();
    final buildingData = buildingSnapshot.data();
    final userData = userSnapshot.data();
    final flatData = flatSnapshot.data();
    final hostId = buildingData?['hostId']?.toString();
    if (hostId != null && hostId.isNotEmpty) {
      final residentName = userData?['name']?.toString() ?? 'A resident';
      final flatNumber = flatData?['flatNumber']?.toString() ?? flatId;
      await _db.notifications.add({
        'userId': hostId,
        'title': 'New access request',
        'body': '$residentName requested access for unit $flatNumber.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return link;
  }

  Future<ResidentLink?> getLinkForUser(String userId) async {
    final query = await _db.residents
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return ResidentLink.fromMap(doc.id, doc.data());
  }

  Future<ResidentLink?> getApprovedLinkForFlat(String flatId) async {
    final query = await _db.residents
        .where('flatId', isEqualTo: flatId)
        .where('approvalStatus', isEqualTo: ApprovalStatus.approved.name)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return ResidentLink.fromMap(doc.id, doc.data());
  }

  Future<FlatResident?> getApprovedResidentForFlat(String flatId) async {
    final link = await getApprovedLinkForFlat(flatId);
    if (link == null) return null;
    final userSnapshot = await _db.users.doc(link.userId).get();
    if (!userSnapshot.exists || userSnapshot.data() == null) {
      return null;
    }
    final user = AppUser.fromMap(userSnapshot.id, userSnapshot.data()!);
    return FlatResident(link: link, user: user);
  }

  Future<List<PendingAccessRequest>> getPendingRequestsForBuilding(
    String buildingId,
  ) async {
    final query = await _db.residents
        .where('buildingId', isEqualTo: buildingId)
        .where('approvalStatus', isEqualTo: ApprovalStatus.pending.name)
        .get();

    if (query.docs.isEmpty) return const [];

    final links = query.docs
        .map((doc) => ResidentLink.fromMap(doc.id, doc.data()))
        .toList();
    final requests = await Future.wait(
      links.map((link) async {
        final userSnapshot = await _db.users.doc(link.userId).get();
        final flatSnapshot = await _db.flats.doc(link.flatId).get();

        final user = userSnapshot.exists && userSnapshot.data() != null
            ? AppUser.fromMap(userSnapshot.id, userSnapshot.data()!)
            : null;
        final flat = flatSnapshot.exists && flatSnapshot.data() != null
            ? Flat.fromMap(flatSnapshot.id, flatSnapshot.data()!)
            : null;

        return PendingAccessRequest(
          link: link,
          residentName: user?.name ?? 'Unknown resident',
          residentEmail: user?.email ?? 'No email',
          flatNumber: flat?.flatNumber ?? link.flatId,
        );
      }),
    );

    requests.sort((a, b) {
      final aTime = a.link.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.link.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return requests;
  }

  Future<void> approveAccessRequest(ResidentLink link) async {
    await _db.residents.doc(link.id).update({
      'approvalStatus': ApprovalStatus.approved.name,
    });

    await _db.flats.doc(link.flatId).update({
      'status': FlatStatus.occupied.name,
    });
    await _db.users.doc(link.userId).update({'buildingId': link.buildingId});

    await _db.notifications.add({
      'userId': link.userId,
      'title': 'Access approved',
      'body': 'Your building access request has been approved.',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> declineAccessRequest(ResidentLink link) async {
    await _db.residents.doc(link.id).delete();
    await _db.notifications.add({
      'userId': link.userId,
      'title': 'Access declined',
      'body': 'Your building access request was declined by host.',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> evictAndReleaseUnit({required String flatId}) async {
    final link = await getApprovedLinkForFlat(flatId);
    final batch = _db.flats.firestore.batch();
    batch.update(_db.flats.doc(flatId), {'status': FlatStatus.vacant.name});

    if (link != null) {
      batch.delete(_db.residents.doc(link.id));
      batch.update(_db.users.doc(link.userId), {'buildingId': null});
      batch.set(_db.notifications.doc(), {
        'userId': link.userId,
        'title': 'Unit access removed',
        'body': 'Your access has been revoked for this unit.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}

class FlatResident {
  final ResidentLink link;
  final AppUser user;

  const FlatResident({required this.link, required this.user});
}

class PendingAccessRequest {
  final ResidentLink link;
  final String residentName;
  final String residentEmail;
  final String flatNumber;

  const PendingAccessRequest({
    required this.link,
    required this.residentName,
    required this.residentEmail,
    required this.flatNumber,
  });
}
