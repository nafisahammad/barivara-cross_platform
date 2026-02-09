import 'enums.dart';
import 'firestore_utils.dart';

class Issue {
  final String id;
  final String residentId;
  final String buildingId;
  final String flatId;
  final String category;
  final String description;
  final IssuePriority priority;
  final IssueStatus status;
  final DateTime? createdAt;

  const Issue({
    required this.id,
    required this.residentId,
    required this.buildingId,
    required this.flatId,
    required this.category,
    required this.description,
    required this.priority,
    required this.status,
    this.createdAt,
  });

  factory Issue.fromMap(String id, Map<String, dynamic> data) {
    return Issue(
      id: id,
      residentId: (data['residentId'] ?? '') as String,
      buildingId: (data['buildingId'] ?? '') as String,
      flatId: (data['flatId'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      priority: IssuePriority.values.byName((data['priority'] ?? 'low') as String),
      status: IssueStatus.values.byName((data['status'] ?? 'open') as String),
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'residentId': residentId,
      'buildingId': buildingId,
      'flatId': flatId,
      'category': category,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'createdAt': toTimestamp(createdAt),
    };
  }
}
