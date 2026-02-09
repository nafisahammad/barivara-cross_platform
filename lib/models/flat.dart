import 'enums.dart';

class Flat {
  final String id;
  final String buildingId;
  final String flatNumber;
  final int floor;
  final double rentAmount;
  final FlatStatus status;

  const Flat({
    required this.id,
    required this.buildingId,
    required this.flatNumber,
    required this.floor,
    required this.rentAmount,
    required this.status,
  });

  factory Flat.fromMap(String id, Map<String, dynamic> data) {
    return Flat(
      id: id,
      buildingId: (data['buildingId'] ?? '') as String,
      flatNumber: (data['flatNumber'] ?? '') as String,
      floor: (data['floor'] ?? 0) as int,
      rentAmount: (data['rentAmount'] ?? 0).toDouble(),
      status: FlatStatus.values.byName((data['status'] ?? 'vacant') as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'flatNumber': flatNumber,
      'floor': floor,
      'rentAmount': rentAmount,
      'status': status.name,
    };
  }
}
