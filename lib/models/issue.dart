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
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final DateTime? slaDueAt;
  final String? assigneeName;
  final String? assigneePhone;
  final List<String> attachments;

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
    this.updatedAt,
    this.resolvedAt,
    this.slaDueAt,
    this.assigneeName,
    this.assigneePhone,
    this.attachments = const [],
  });

  factory Issue.fromMap(String id, Map<String, dynamic> data) {
    final rawAttachments = data['attachments'];
    final attachments = rawAttachments is Iterable
        ? rawAttachments
            .map((item) => item?.toString())
            .whereType<String>()
            .toList()
        : const <String>[];
    final rawPriority = data['priority']?.toString();
    final rawStatus = data['status']?.toString();
    return Issue(
      id: id,
      residentId: (data['residentId'] ?? '') as String,
      buildingId: (data['buildingId'] ?? '') as String,
      flatId: (data['flatId'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      priority: _parsePriority(rawPriority),
      status: _parseStatus(rawStatus),
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
      resolvedAt: parseDateTime(data['resolvedAt']),
      slaDueAt: parseDateTime(data['slaDueAt']),
      assigneeName: data['assigneeName'] as String?,
      assigneePhone: data['assigneePhone'] as String?,
      attachments: attachments,
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
      'updatedAt': toTimestamp(updatedAt),
      'resolvedAt': toTimestamp(resolvedAt),
      'slaDueAt': toTimestamp(slaDueAt),
      'assigneeName': assigneeName,
      'assigneePhone': assigneePhone,
      'attachments': attachments,
    };
  }
}

IssuePriority _parsePriority(String? value) {
  if (value == null || value.isEmpty) return IssuePriority.low;
  return IssuePriority.values.firstWhere(
    (item) => item.name == value,
    orElse: () => IssuePriority.low,
  );
}

IssueStatus _parseStatus(String? value) {
  if (value == null || value.isEmpty) return IssueStatus.open;
  return IssueStatus.values.firstWhere(
    (item) => item.name == value,
    orElse: () => IssueStatus.open,
  );
}
