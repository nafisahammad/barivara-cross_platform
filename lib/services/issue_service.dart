import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/enums.dart';
import '../models/issue.dart';
import 'db_service.dart';

class IssueService {
  IssueService._();

  static final IssueService instance = IssueService._();

  final DbService _db = DbService.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<Issue>> streamIssuesForBuilding(String buildingId) {
    return _db.issues
        .where('buildingId', isEqualTo: buildingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Issue.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<Issue>> streamIssuesForResident(String userId) {
    return _db.issues
        .where('residentId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Issue.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<Issue>> streamIssuesForFlat(String flatId) {
    return _db.issues
        .where('flatId', isEqualTo: flatId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Issue.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Duration _slaForPriority(IssuePriority priority) {
    switch (priority) {
      case IssuePriority.urgent:
        return const Duration(hours: 6);
      case IssuePriority.high:
        return const Duration(hours: 24);
      case IssuePriority.medium:
        return const Duration(hours: 48);
      case IssuePriority.low:
        return const Duration(hours: 72);
    }
  }

  Future<List<String>> uploadIssueAttachments({
    required String buildingId,
    required String flatId,
    required String residentId,
    required List<XFile> files,
  }) async {
    if (files.isEmpty) return const [];
    final now = DateTime.now().millisecondsSinceEpoch;
    final uploads = files.map((file) async {
      final fileName = file.name.isNotEmpty ? file.name : 'attachment_$now';
      final path =
          'issues/$buildingId/$flatId/$residentId/${now}_$fileName';
      final ref = _storage.ref().child(path);
      await ref.putData(await file.readAsBytes());
      return ref.getDownloadURL();
    });
    return Future.wait(uploads);
  }

  Future<void> createIssue({
    required String residentId,
    required String buildingId,
    required String flatId,
    required String category,
    required String description,
    required IssuePriority priority,
    List<String> attachments = const [],
  }) async {
    final now = DateTime.now();
    final slaDueAt = now.add(_slaForPriority(priority));
    await _db.issues.add({
      'residentId': residentId,
      'buildingId': buildingId,
      'flatId': flatId,
      'category': category,
      'description': description,
      'priority': priority.name,
      'status': IssueStatus.open.name,
      'attachments': attachments,
      'slaDueAt': Timestamp.fromDate(slaDueAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final buildingSnapshot = await _db.buildings.doc(buildingId).get();
    final flatSnapshot = await _db.flats.doc(flatId).get();
    final buildingData = buildingSnapshot.data();
    final flatData = flatSnapshot.data();
    final hostId = buildingData?['hostId']?.toString();
    if (hostId != null && hostId.isNotEmpty) {
      final flatNumber = flatData?['flatNumber']?.toString() ?? flatId;
      await _db.notifications.add({
        'userId': hostId,
        'title': 'New service ticket',
        'body': '$category reported for unit $flatNumber.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateStatus(String issueId, IssueStatus status) async {
    final issueSnapshot = await _db.issues.doc(issueId).get();
    final issueData = issueSnapshot.data();
    await _db.issues.doc(issueId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'resolvedAt': status == IssueStatus.resolved ||
              status == IssueStatus.closed
          ? FieldValue.serverTimestamp()
          : null,
    });

    final residentId = issueData?['residentId']?.toString();
    final category = issueData?['category']?.toString() ?? 'Service ticket';
    if (residentId != null && residentId.isNotEmpty) {
      await _db.notifications.add({
        'userId': residentId,
        'title': 'Ticket status updated',
        'body': '$category is now ${status.name}.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> assignIssue({
    required String issueId,
    required String assigneeName,
    String? assigneePhone,
  }) async {
    final issueSnapshot = await _db.issues.doc(issueId).get();
    final issueData = issueSnapshot.data();
    await _db.issues.doc(issueId).update({
      'assigneeName': assigneeName,
      'assigneePhone': assigneePhone,
      'status': IssueStatus.inProgress.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final residentId = issueData?['residentId']?.toString();
    final category = issueData?['category']?.toString() ?? 'Service ticket';
    if (residentId != null && residentId.isNotEmpty) {
      await _db.notifications.add({
        'userId': residentId,
        'title': 'Ticket assigned',
        'body': '$category assigned to $assigneeName.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
