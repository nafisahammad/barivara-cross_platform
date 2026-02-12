import '../models/enums.dart';
import '../models/payment.dart';
import 'db_service.dart';

class PaymentService {
  PaymentService._();

  static final PaymentService instance = PaymentService._();

  final DbService _db = DbService.instance;

  Future<double> getTotalRevenueForBuilding(String buildingId) async {
    final query = await _db.payments
        .where('buildingId', isEqualTo: buildingId)
        .get();
    final payments = query.docs.map(
      (doc) => Payment.fromMap(doc.id, doc.data()),
    );
    return payments
        .where((payment) => payment.status == PaymentStatus.confirmed)
        .fold<double>(0.0, (total, payment) => total + payment.amount);
  }

  Future<double> getBalanceDueForResident(String residentId) async {
    final query = await _db.payments
        .where('residentId', isEqualTo: residentId)
        .get();
    final payments = query.docs.map(
      (doc) => Payment.fromMap(doc.id, doc.data()),
    );
    return payments
        .where(
          (payment) =>
              payment.status == PaymentStatus.due ||
              payment.status == PaymentStatus.pendingApproval,
        )
        .fold<double>(0.0, (total, payment) => total + payment.amount);
  }

  Future<double> getRentDueForResident(String residentId) async {
    final query = await _db.payments
        .where('residentId', isEqualTo: residentId)
        .get();
    final payments = query.docs.map(
      (doc) => Payment.fromMap(doc.id, doc.data()),
    );
    return payments
        .where(
          (payment) =>
              payment.category == PaymentCategory.rent &&
              (payment.status == PaymentStatus.due ||
                  payment.status == PaymentStatus.pendingApproval),
        )
        .fold<double>(0.0, (total, payment) => total + payment.amount);
  }

  Future<List<Payment>> getPaymentsForFlat(String flatId) async {
    final query = await _db.payments.where('flatId', isEqualTo: flatId).get();
    final payments = query.docs
        .map((doc) => Payment.fromMap(doc.id, doc.data()))
        .toList();
    payments.sort((a, b) {
      final aDate =
          a.paidAt ?? a.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          b.paidAt ?? b.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return payments;
  }
}
