import 'enums.dart';
import 'firestore_utils.dart';

class Payment {
  final String id;
  final String residentId;
  final String buildingId;
  final String flatId;
  final double amount;
  final PaymentCategory category;
  final PaymentStatus status;
  final DateTime? dueDate;
  final DateTime? paidAt;

  const Payment({
    required this.id,
    required this.residentId,
    required this.buildingId,
    required this.flatId,
    required this.amount,
    required this.category,
    required this.status,
    this.dueDate,
    this.paidAt,
  });

  factory Payment.fromMap(String id, Map<String, dynamic> data) {
    return Payment(
      id: id,
      residentId: (data['residentId'] ?? '') as String,
      buildingId: (data['buildingId'] ?? '') as String,
      flatId: (data['flatId'] ?? '') as String,
      amount: (data['amount'] ?? 0).toDouble(),
      category: PaymentCategory.values.byName((data['category'] ?? 'rent') as String),
      status: PaymentStatus.values.byName((data['status'] ?? 'pendingApproval') as String),
      dueDate: parseDateTime(data['dueDate']),
      paidAt: parseDateTime(data['paidAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'residentId': residentId,
      'buildingId': buildingId,
      'flatId': flatId,
      'amount': amount,
      'category': category.name,
      'status': status.name,
      'dueDate': toTimestamp(dueDate),
      'paidAt': toTimestamp(paidAt),
    };
  }
}
