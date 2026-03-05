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

  Future<List<Payment>> getPaymentsForBuilding(String buildingId) async {
    final query = await _db.payments
        .where('buildingId', isEqualTo: buildingId)
        .get();
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

  Future<Payment> createPaymentRequest({
    required String residentId,
    required String buildingId,
    required String flatId,
    required double amount,
    required PaymentCategory category,
    DateTime? dueDate,
  }) async {
    final doc = _db.payments.doc();
    final payment = Payment(
      id: doc.id,
      residentId: residentId,
      buildingId: buildingId,
      flatId: flatId,
      amount: amount,
      category: category,
      status: PaymentStatus.pendingApproval,
      dueDate: dueDate,
      paidAt: DateTime.now(),
    );
    await doc.set(payment.toMap());
    return payment;
  }

  Future<void> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    DateTime? paidAt,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
    };
    if (status == PaymentStatus.confirmed) {
      updates['paidAt'] = paidAt == null ? DateTime.now() : paidAt;
    }
    if (status == PaymentStatus.due) {
      updates['paidAt'] = null;
    }
    await _db.payments.doc(paymentId).update(updates);
  }
}
