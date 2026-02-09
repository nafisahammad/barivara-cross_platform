import 'package:cloud_firestore/cloud_firestore.dart';

class DbService {
  DbService._();

  static final DbService instance = DbService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get passwords => _db.collection('passwords');
  CollectionReference<Map<String, dynamic>> get buildings => _db.collection('buildings');
  CollectionReference<Map<String, dynamic>> get flats => _db.collection('flats');
  CollectionReference<Map<String, dynamic>> get residents => _db.collection('residents');
  CollectionReference<Map<String, dynamic>> get payments => _db.collection('payments');
  CollectionReference<Map<String, dynamic>> get issues => _db.collection('issues');
  CollectionReference<Map<String, dynamic>> get community => _db.collection('community');
  CollectionReference<Map<String, dynamic>> get notices => _db.collection('notices');
  CollectionReference<Map<String, dynamic>> get contacts => _db.collection('contacts');
  CollectionReference<Map<String, dynamic>> get notifications => _db.collection('notifications');
}
