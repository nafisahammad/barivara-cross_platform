import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums.dart';
import '../models/issue.dart';
import 'db_service.dart';

class IssueService {
  IssueService._();

  static final IssueService instance = IssueService._();

  final DbService _db = DbService.instance;

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

  Future<void> createIssue({
    required String residentId,
    required String buildingId,
    required String flatId,
    required String category,
    required String description,
    required IssuePriority priority,
  }) async {
    await _db.issues.add({
      'residentId': residentId,
      'buildingId': buildingId,
      'flatId': flatId,
      'category': category,
      'description': description,
      'priority': priority.name,
      'status': IssueStatus.open.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus(String issueId, IssueStatus status) async {
    await _db.issues.doc(issueId).update({'status': status.name});
  }
}
