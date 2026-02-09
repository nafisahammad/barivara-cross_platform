import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Timestamp? toTimestamp(DateTime? value) {
  if (value == null) return null;
  return Timestamp.fromDate(value);
}
