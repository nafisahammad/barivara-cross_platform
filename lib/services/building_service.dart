import 'dart:math';


import '../models/building.dart';
import '../models/enums.dart';
import '../models/flat.dart';
import 'db_service.dart';

class BuildingService {
  BuildingService._();

  static final BuildingService instance = BuildingService._();

  final DbService _db = DbService.instance;

  Future<Building> createBuilding({
    required String hostId,
    required String name,
    required String address,
    required int floors,
    required int unitsPerFloor,
  }) async {
    final inviteCode = await _generateUniqueInviteCode();

    final doc = _db.buildings.doc();
    final building = Building(
      id: doc.id,
      hostId: hostId,
      name: name,
      address: address,
      inviteCode: inviteCode,
      rules: const [],
    );

    final batch = _db.buildings.firestore.batch();
    batch.set(doc, building.toMap());

    final flats = _generateFlats(buildingId: building.id, floors: floors, unitsPerFloor: unitsPerFloor);
    for (final flat in flats) {
      final flatDoc = _db.flats.doc();
      batch.set(flatDoc, flat.copyWith(id: flatDoc.id).toMap());
    }

    await batch.commit();
    return building;
  }

  Future<Building?> findBuildingByInviteCode(String code) async {
    final query = await _db.buildings.where('inviteCode', isEqualTo: code).limit(1).get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return Building.fromMap(doc.id, doc.data());
  }

  Future<Building?> getBuildingForHost(String hostId) async {
    final query = await _db.buildings.where('hostId', isEqualTo: hostId).limit(1).get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return Building.fromMap(doc.id, doc.data());
  }

  Future<List<Flat>> getVacantFlats(String buildingId) async {
    final query = await _db.flats
        .where('buildingId', isEqualTo: buildingId)
        .where('status', isEqualTo: FlatStatus.vacant.name)
        .get();
    return query.docs.map((doc) => Flat.fromMap(doc.id, doc.data())).toList();
  }

  List<Flat> _generateFlats({
    required String buildingId,
    required int floors,
    required int unitsPerFloor,
  }) {
    final flats = <Flat>[];
    for (var floor = 1; floor <= floors; floor++) {
      final floorLabel = _floorLabel(floor);
      for (var unit = 1; unit <= unitsPerFloor; unit++) {
        flats.add(
          Flat(
            id: '',
            buildingId: buildingId,
            flatNumber: '$floorLabel-$unit',
            floor: floor,
            rentAmount: 0,
            status: FlatStatus.vacant,
          ),
        );
      }
    }
    return flats;
  }

  String _floorLabel(int floor) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (floor <= letters.length) return letters[floor - 1];
    return 'F$floor';
  }

  Future<String> _generateUniqueInviteCode() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _randomInviteCode();
      final existing = await _db.buildings.where('inviteCode', isEqualTo: code).limit(1).get();
      if (existing.docs.isEmpty) return code;
    }
    return _randomInviteCode();
  }

  String _randomInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}

extension on Flat {
  Flat copyWith({
    String? id,
    String? buildingId,
    String? flatNumber,
    int? floor,
    double? rentAmount,
    FlatStatus? status,
  }) {
    return Flat(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      flatNumber: flatNumber ?? this.flatNumber,
      floor: floor ?? this.floor,
      rentAmount: rentAmount ?? this.rentAmount,
      status: status ?? this.status,
    );
  }
}
