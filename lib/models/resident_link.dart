import 'enums.dart';
import 'firestore_utils.dart';

class ResidentLink {
  final String id;
  final String userId;
  final String buildingId;
  final String flatId;
  final ApprovalStatus approvalStatus;
  final DateTime? createdAt;

  const ResidentLink({
    required this.id,
    required this.userId,
    required this.buildingId,
    required this.flatId,
    required this.approvalStatus,
    this.createdAt,
  });

  factory ResidentLink.fromMap(String id, Map<String, dynamic> data) {
    return ResidentLink(
      id: id,
      userId: (data['userId'] ?? '') as String,
      buildingId: (data['buildingId'] ?? '') as String,
      flatId: (data['flatId'] ?? '') as String,
      approvalStatus: ApprovalStatus.values.byName((data['approvalStatus'] ?? 'pending') as String),
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'buildingId': buildingId,
      'flatId': flatId,
      'approvalStatus': approvalStatus.name,
      'createdAt': toTimestamp(createdAt),
    };
  }
}
