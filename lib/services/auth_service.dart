import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/enums.dart';
import 'db_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DbService _db = DbService.instance;

  String? _verificationId;
  ConfirmationResult? _webConfirmation;
  String? _localUserId;

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid ?? _localUserId;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final firebaseUserId = _auth.currentUser?.uid;
    if (firebaseUserId != null && firebaseUserId.isNotEmpty) {
      _localUserId = firebaseUserId;
      await prefs.setString('localUserId', firebaseUserId);
      return;
    }
    _localUserId = prefs.getString('localUserId');
  }

  Future<void> startPhoneSignIn(String phoneNumber) async {
    if (kIsWeb) {
      _webConfirmation = await _auth.signInWithPhoneNumber(phoneNumber);
      return;
    }

    final completer = Completer<void>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        if (!completer.isCompleted) completer.complete();
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      codeSent: (verificationId, _) {
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future;
  }

  Future<User> verifySmsCode(String smsCode) async {
    if (kIsWeb) {
      final confirmation = _webConfirmation;
      if (confirmation == null) {
        throw StateError('Start phone sign-in first.');
      }
      final credential = await confirmation.confirm(smsCode);
      return credential.user!;
    }

    final verificationId = _verificationId;
    if (verificationId == null) {
      throw StateError('Start phone sign-in first.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user!;
  }

  Future<AppUser?> getCurrentProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;
    final snapshot = await _db.users.doc(userId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AppUser.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<AppUser?> findUserByPhone(String phone) async {
    final query = await _db.users.where('phone', isEqualTo: phone).limit(1).get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return AppUser.fromMap(doc.id, doc.data());
  }

  Future<AppUser> registerProfile({
    required String name,
    required String phone,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please verify your phone number first.');
    }

    final profile = AppUser(
      id: user.uid,
      name: name,
      phone: phone,
      role: UserRole.resident,
      buildingId: null,
    );

    await _db.users.doc(user.uid).set(profile.toMap());
    await _db.passwords.doc(user.uid).set({'value': password});
    _localUserId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('localUserId', user.uid);
    return profile;
  }

  Future<AppUser> loginProfile({
    required String phone,
    required String password,
  }) async {
    final profile = await findUserByPhone(phone);
    if (profile == null) {
      throw StateError('No account found for that phone number.');
    }
    final passwordSnapshot = await _db.passwords.doc(profile.id).get();
    if (!passwordSnapshot.exists || passwordSnapshot.data() == null) {
      throw StateError('Password not set for this account.');
    }
    final storedPassword = passwordSnapshot.data()!['value']?.toString() ?? '';
    if (storedPassword != password) {
      throw StateError('Incorrect password.');
    }
    _localUserId = profile.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('localUserId', profile.id);
    return profile;
  }

  Future<void> updateRole(UserRole role) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('No authenticated user.');
    await _db.users.doc(userId).update({'role': role.name});
  }

  Future<void> setBuildingId(String buildingId) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('No authenticated user.');
    await _db.users.doc(userId).update({'buildingId': buildingId});
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _localUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('localUserId');
  }
}
